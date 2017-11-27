//
//  FHIREnum.swift
//  SwiftFHIR
//
//  Created by Pascal Pfiffner on 08.12.16.
//  2016, SMART Health IT.
//

import Foundation


/**
Attempt to create an enum for the given key in the given dictionary, filling presentKeys and errors along the way.

- parameter type:    The enum type to create (as an array)
- parameter key:     The JSON key to look at in `json`
- parameter json:    The JSON dictionary to inspect
- parameter context: The instantiation context to use
- returns:           An array of enums, or nil
*/
public func createEnum<E: RawRepresentable>(type: E.Type, for key: String, in json: FHIRJSON, context: inout FHIRInstantiationContext) -> E? {
	guard let exist = json[key] else {
		return nil
	}
	context.insertKey(key)
	
	// correct type?
	guard let value = exist as? E.RawValue else {
		context.addError(FHIRValidationError(key: key, wants: E.RawValue.self, has: type(of: exist)))
		return nil
	}
	
	// create enum
	guard let enumval = E(rawValue: value) else {
		context.addError(FHIRValidationError(key: key, problem: "“\(value)” is not valid"))
		return nil
	}
	if let _ = json["_\(key)"] as? FHIRJSON {
		context.insertKey("_\(key)")
		// TODO: populate from "_key"
		fhir_warn("Not implemented: extension for enums for key “_\(key)”")
	}
	return enumval
}


/**
Attempt to create an array of enums for the given key in the given dictionary, populating presentKeys and errors appropriately.

- parameter type:    The enum type to create (as an array)
- parameter key:     The JSON key to look at in `json`
- parameter json:    The JSON dictionary to inspect
- parameter context: The instantiation context to use
- returns:           An array of enums, or nil
*/
public func createEnums<E: RawRepresentable>(of type: E.Type, for key: String, in json: FHIRJSON, context: inout FHIRInstantiationContext) -> [E]? {
	guard let exist = json[key] else {
		return nil
	}
	context.insertKey(key)
	
	// correct type?
	guard let val = exist as? [E.RawValue] else {
		context.addError(FHIRValidationError(key: key, wants: Array<E.RawValue>.self, has: type(of: exist)))
		return nil
	}
	
	// loop over raw values and create enums
	var enums = [E]()
	for (i, value) in val.enumerated() {
		guard let enumval = E(rawValue: value) else {
			context.addError(FHIRValidationError(key: "\(key).\(i)", problem: "“\(value)” is not valid"))
			continue
		}
		enums.append(enumval)
	}
	if let _ = json["_\(key)"] as? FHIRJSON {
		context.insertKey("_\(key)")
		// TODO: populate from "_key"
		fhir_warn("Not implemented: extension for enums for key “_\(key)”")
	}
	return enums
}


extension RawRepresentable {
	
	public func decorate(json: inout FHIRJSON, withKey key: String, errors: inout [FHIRValidationError]) {
		json[key] = rawValue
		// TODO: fill "_key"
	}
}


public func arrayDecorate<E: RawRepresentable>(json: inout FHIRJSON, withKey key: String, using array: [E]?, errors: inout [FHIRValidationError]) {
	guard let array = array else {
		return
	}
	let arr = array.map() { $0.rawValue }
	json[key] = arr
	// TODO: fill "_key"
}

