//
//  RedCapModels.swift
//  AI4PDDemo
//
//  Created by Tim_Feige on 29.09.23.
//

import Foundation

struct RCInstrument: Codable {
    var instrumentName: String
    var instrumentLabel: String

        enum CodingKeys: String, CodingKey {
            case instrumentName = "instrument_name"
            case instrumentLabel = "instrument_label"
        }
}

enum FieldType: String, Codable {
    case text //textbox
    case notes //notebox
    case calc //calculated Field
    case dropdown //multiple choice
    case radio
    case checkbox
    case yesno
    case truefalse
    case file
    case slider
    case descriptive
    //section header if there will be in the field
    case sql
}

struct RCField: Codable, Identifiable {
    var fieldName: String
    var answer: String = "" //better option?
    var updated: Bool = false
    var formName, sectionHeader: String?
    let fieldType: FieldType
    var fieldLabel, selectChoicesOrCalculations, fieldNote, textValidationTypeOrShowSliderNumber: String?
    var textValidationMin, textValidationMax, identifier, branchingLogic: String?
    var requiredField, customAlignment, questionNumber, matrixGroupName: String?
    var matrixRanking, fieldAnnotation: String?
    
    // Conform to Identifiable using fieldName as the id
        var id: String { fieldName }

    enum CodingKeys: String, CodingKey {
        case fieldName = "field_name"
        case formName = "form_name"
        case sectionHeader = "section_header"
        case fieldType = "field_type"
        case fieldLabel = "field_label"
        case selectChoicesOrCalculations = "select_choices_or_calculations"
        case fieldNote = "field_note"
        case textValidationTypeOrShowSliderNumber = "text_validation_type_or_show_slider_number"
        case textValidationMin = "text_validation_min"
        case textValidationMax = "text_validation_max"
        case identifier
        case branchingLogic = "branching_logic"
        case requiredField = "required_field"
        case customAlignment = "custom_alignment"
        case questionNumber = "question_number"
        case matrixGroupName = "matrix_group_name"
        case matrixRanking = "matrix_ranking"
        case fieldAnnotation = "field_annotation"
    }
}

struct RCBranchingLogic {
    let fieldName: String
    let checkboxNumber: String
    let op: String
    let right: String
    let concat: String
}
