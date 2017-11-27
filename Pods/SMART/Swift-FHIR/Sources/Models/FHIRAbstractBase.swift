//
//  FHIRAbstractBase.swift
//  SwiftFHIR
//
//  Created by Pascal Pfiffner on 7/2/14.
//  2014, SMART Health IT.
//

import Foundation


/**
Abstract superclass for all FHIR data elements.
*/
open class FHIRAbstractBase: FHIRJSONType, CustomStringConvertible, CustomDebugStringConvertible {
	
	public typealias JSONType = FHIRJSON
	
	/// The type of the resource or element.
	open class var resourceType: String {
		get { return "FHIRAbstractBase" }
	}
	
	/// The parent/owner of the receiver, if any. Used to dereference resources.
	public weak var _owner: FHIRAbstractBase?
	
	/// Resolved references.
	var _resolved: [String: Resource]?
	
	/// Whether this element/resource is (part of) a subsetted/summarized resource.
	public var _isSummaryResource: Bool {
		if let this = self as? Resource {
			return this._isSummary
		}
		return _owningResource?._isSummary ?? false
	}
	
	
	/**
	Throwing initializer, made “required” so instantiation with a metatype is possible.
	
	Forwards to `populate(from:context:)` and then validates the instantiation, throwing on error.
	
	- parameter json:  The JSON element to use to populate the receiver
	- parameter owner: If the receiver is an element or a resource in another resource, this references that "owner"
	- throws:          FHIRValidationError, if any
	*/
	public required init(json: FHIRJSON, owner: FHIRAbstractBase? = nil) throws {
		_owner = owner
		var context = FHIRInstantiationContext()
		populateAndFinalize(from: json, context: &context)
		try context.validate()
	}
	
	/**
	Designated initializer, made “required” so instantiation with a metatype is possible.
	
	Forwards to `populate(from:context:)`. You can then validate the instantiation yourself by calling `try context.validate()`.
	
	- parameter json:    The JSON element to use to populate the receiver
	- parameter owner:   If the receiver is an element or a resource in another resource, this references that "owner"
	- parameter context: An in-out parameter for the instantiation context
	*/
	public required init(json: FHIRJSON, owner: FHIRAbstractBase? = nil, context: inout FHIRInstantiationContext) {
		_owner = owner
		populateAndFinalize(from: json, context: &context)
	}
	
	/**
	Basic initializer for easy construction of new instances in code.
	
	- parameter owner: An optional owner of the element or resource
	*/
	public init(owner: FHIRAbstractBase? = nil) {
		_owner = owner
	}
	
	
	// MARK: - FHIRJSONType
	
	/**
	FHIRAbstractBase simply forwards to `self.init(json:owner:)`. Use `FHIRAbstractResource`'s implementation if you wish to inspect the
	json for `resourceType`, which will then use the factory method.
	
	- parameter json:    A FHIRJSON decoded from a JSON response
	- parameter owner:   The FHIRAbstractBase owning the new instance, if appropriate
	- parameter context: An in-out parameter for the instantiation context
	- returns:           An instance of self, instantiated from the given JSON dictionary
	*/
	public class func instantiate(from json: FHIRJSON, owner: FHIRAbstractBase?, context: inout FHIRInstantiationContext) -> Self {
		return self.init(json: json, owner: owner, context: &context)   // must use 'required' init with dynamic type
	}
	
	/**
	Will populate instance variables - overriding existing ones - with values found in the supplied JSON. Calls `populate(json:context:)`,
	which is what you should override instead.
	
	This is an exact copy of what's implemented as an extension to `FHIRJSONType` but is needed to be picked up by the classes.
	
	- parameter json:    The JSON element to use to populate the receiver
	- parameter context: An in-out parameter being filled with key names used.
	*/
	public final func populateAndFinalize(from json: FHIRJSON, context: inout FHIRInstantiationContext) {
		context.insertKey("fhir_comments")
		populate(from: json, context: &context)
		
		// finalize
		context.finalize(for: json)
		if nil == _owner {
			context.prefixErrors(with: "\(type(of: self))")
		}
	}
	
	/**
	The main function to perform the actual JSON parsing, to be overridden by subclasses.
	 
	- parameter json:    The JSON element to use to populate the receiver
	- parameter context: The instantiation context to use
	*/
	public func populate(from json: FHIRJSON, context: inout FHIRInstantiationContext) {
	}
	
	/**
	Represent the receiver in FHIRJSON, ready to be used for JSON serialization.
	
	- returns: The FHIRJSON reperesentation of the receiver
	*/
	public final func asJSON() throws -> JSONType {
		var errors = [FHIRValidationError]()
		let json = asJSON(errors: &errors)
		if !errors.isEmpty {
			throw FHIRValidationError(errors: errors)
		}
		return json
	}
	
	/**
	Represent the receiver in FHIRJSON, ready to be used for JSON serialization. Non-throwing version that you can use if you want to handle
	errors yourself or ignore them altogether. Otherwise, just use `asJSON() throws`.
	
	- parameter errors: The array that will be filled with FHIRValidationError instances, if there are any
	- returns: The FHIRJSON reperesentation of the receiver
	*/
	public final func asJSON(errors: inout [FHIRValidationError]) -> JSONType {
		var json = FHIRJSON()
		decorate(json: &json, errors: &errors)
		return json
	}
	
	public final func decorate(json: inout FHIRJSON, withKey key: String, errors: inout [FHIRValidationError]) {
		json[key] = asJSON(errors: &errors)
	}
	
	open func decorate(json: inout FHIRJSON, errors: inout [FHIRValidationError]) {
	}
	
	
	// MARK: - Resolving References
	
	/** Returns the resolved reference with the given id, if it has been resolved already. */
	public func resolvedReference(_ refid: String) -> Resource? {
		if let resolved = _resolved?[refid] {
			return resolved
		}
		return _owner?.resolvedReference(refid)
	}
	
	/**
	Stores the resolved reference into the `_resolved` dictionary.
	
	This method is public because it's used in an extension in our client. You likely don't need to use it explicitly, use the
	`resolve(type:callback:)` method on `Reference` instead.
	
	- parameter refid: The reference identifier as String
	- parameter resolved: The resource that was resolved
	*/
	public func didResolveReference(_ refid: String, resolved: Resource) {
		if nil != _resolved {
			_resolved![refid] = resolved
		}
		else {
			_resolved = [refid: resolved]
		}
	}
	
	/**
	The resource owning the receiver; used during reference resolving and to look up the instance's `_server`, if any.
	
	- returns: The owning `DomainResource` instance or nil
	*/
	open var _owningResource: DomainResource? {
		var owner = _owner
		while nil != owner {
			if let owner = owner as? DomainResource {
				return owner
			}
			owner = owner?._owner
		}
		return nil
	}
	
	/**
	Returns the receiver's owning Bundle, if it has one.
	
	- returns: The owning `Bundle` instance or nil
	*/
	open var _owningBundle: Bundle? {
		var owner = _owner
		while nil != owner {
			if let owner = owner as? Bundle {
				return owner
			}
			owner = owner?._owner
		}
		return nil
	}
	
	
	// MARK: - CustomStringConvertible
	
	open var description: String {
		return "<\(type(of: self).resourceType)>"
	}
	
	/// The debug description pretty-prints the Element/Resource's JSON representation.
	open var debugDescription: String {
		if let json = try? asJSON(), let data = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted), let str = String(data: data, encoding: String.Encoding.utf8) {
			return str
		}
		return description
	}
}


/**
Inspects the given dictionary for an array with the given key, and if successful instantiates an array of the desired FHIR objects.

Unable to make this a class method on FHIRAbstractBase as it would need to be implemented on every subclass in order to not return
`FHIRAbstractBase` all the time.

- parameter type:   The FHIR object that is expected
- parameter key:    The key for which to look in `json`
- parameter json:   The JSON dictionary to search through
- parameter presentKeys: An inout set of keys found in the JSON
- parameter errors: An inout array of validation errors found
- parameter owner:  The FHIRAbstractBase owning the new instance, if appropriate
- returns:          An array of the desired FHIRAbstractBase subclasses (or nil)
*/
public func instantiate<T: FHIRAbstractBase>(type: T.Type, for key: String, in json: FHIRJSON, presentKeys: inout Set<String>, errors: inout [FHIRValidationError], owner: FHIRAbstractBase? = nil) throws -> [T]? {
	guard let exist = json[key] else {
		return nil
	}
	presentKeys.insert(key)
	
	// correct type?
	guard let arr = exist as? [T.JSONType] else {
		errors.append(FHIRValidationError(key: key, wants: Array<T.JSONType>.self, has: type(of: exist)))
		return nil
	}
	
	// loop over dicts and create instances
	var instances = [T]()
	for (i, value) in arr.enumerated() {
		do {
			instances.append(try T(json: value, owner: owner))
		}
		catch let error as FHIRValidationError {
			errors.append(error.prefixed(with: "\(key).\(i)"))
		}
	}
	return instances.isEmpty ? nil : instances
}

