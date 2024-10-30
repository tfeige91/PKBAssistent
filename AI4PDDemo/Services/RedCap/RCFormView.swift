//
//  RCFormView.swift
//  AI4PDDemo
//
//  Created by Tim_Feige on 29.09.23.
//

import SwiftUI
import RegexBuilder

struct WidthPreference: PreferenceKey {
    static var defaultValue: CGFloat = 0.0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        
        value = nextValue()
    }
}

struct RCFormView: View {
    let rc = RedCapAPIService.instance
    
    @State private var surveyItems: [RCField] = []
    @State private var frames: [Namespace.ID:CGRect] = [:]
    @State private var questionnaire: String = ""
    @State private var width: CGFloat = 0.0
    let alternatingRowColor = Color.gray.opacity(0.1)
    
    
    var body: some View {
        //GeometryReader{ geo in
            ScrollView {
                VStack(alignment: .leading) {
                    ForEach($surveyItems) {$item in
                        if evaluateBranching(field: $item.wrappedValue, surveyItems: self.surveyItems){
                            RCItemView(field: $item, width: self.width)
                                
                        }
                        
                    }
                    
                    Rectangle()
                        .fill(alternatingRowColor)
                        .frame(height: 3)
                        .frame(maxWidth: .infinity)
                    
                    Button {
                        Task {
                            let filtered = surveyItems.filter {$0.updated}
                            try await RedCapAPIService.instance.uploadRecord(record: filtered)
                            //print(filtered)
                            // clear updated
                            _ = surveyItems.enumerated().filter { (index, field) in
                                return field.updated == true
                            }.map {// indexes
                                self.surveyItems[$0.0].updated = false
                            }
                        }
                        
                    } label: {
                        HStack(alignment: .center){
                            Text("Absenden")
                                .foregroundStyle(.white)
                                .font(.headline)
                                .bold()
                                .padding(30)
                                .background(Color.accentColor)
                                .clipShape(RoundedRectangle(cornerRadius: 10))

                        }
                        .padding(.top, 40)
                        .frame(maxWidth: .infinity)
                    }
                    
                    
                }
                .overlay(){
                    GeometryReader{geo in
                        let w = geo.size.width
                        Color.clear
                            .onAppear{width = w}
                            .onChange(of: w){width = $0}
                            .preference(key: WidthPreference.self, value: w)
                    }
                }
            }
            .useStickyHeaders() //enabling sticky Matrix Headers
             
        //}
        .navigationTitle(questionnaire)
        .onAppear {
//            UserDefaults.standard.set("99", forKey: "RecordId")
//            let decoder = JSONDecoder()
//            guard let surveyFields = try? decoder.decode([RCField].self, from: jsonData!) else {
//                fatalError("Decoding failed")
//            }
//            //print(surveyFields)
//            self.surveyItems = surveyFields
            Task{
                let allQuests = try await rc.fetchInstruments()
                let quest = try await rc.fetchInstrument(allQuests[0].instrumentLabel)
                self.questionnaire = allQuests[0].instrumentLabel
                //filter record ID field
                self.surveyItems = quest.filter({ $0.fieldName != "record_id"
                })
            }
           
        }
        
    }
    
     
    //MARK: - TextFieldView
    @ViewBuilder
    func RCTextFieldView(field: Binding<RCField>,index:Int,width:CGFloat) -> some View {
        HStack{
            QuestionLabel(field: field)
            
            
            TextField("",
                      text: Binding(
                        get: { field.wrappedValue.answer },
                        set: { newValue in
                            withAnimation {
                                field.wrappedValue.answer = newValue
                            }
                        }),
                      onEditingChanged: { _ in
                field.wrappedValue.updated = true }
            )
            .textFieldStyle(.roundedBorder)
            .padding()
            //.frame(width: (geo.size.width * 0.65))
            .frame(width: (width * 0.65))
            
        }
    }
//    
//    @ViewBuilder
//    func RCRadioButtonView(field: Binding<RCField>) -> some View {
//        let matrixHeader = field.matrixGroupName.wrappedValue
//        let (choiceNumber,choiceLabel) = parseSelectChoicesOrCalculations(field: field.wrappedValue)
//        
//        //if matrixHeader != nil apply Sticky to the choiceLabels
//        
//    }
    
    
    @ViewBuilder
    func QuestionLabel(field: Binding<RCField>) -> some View {
        Text(field.wrappedValue.fieldLabel ?? "")
            .fixedSize(horizontal: false, vertical: true)
            .frame(minWidth: 0, maxWidth: .infinity,alignment: .leading)
            .padding(20)
    }
    
    @ViewBuilder
    func RadioButtonCheckboxes(field: Binding<RCField>, cNumber: [String]? = nil,index:Int,width:CGFloat) -> some View {
        
        if let choiceNumber = cNumber {
            HStack(spacing: 0) {
                QuestionLabel(field: field)

                ForEach(0..<choiceNumber.count, id: \.self) { optionIndex in
                    Button(action: {
                        field.wrappedValue.answer = String(choiceNumber[optionIndex])
                        field.wrappedValue.updated = true
                    }) {
                        Image(systemName: field.wrappedValue.answer == String(choiceNumber[optionIndex]) ? "checkmark.square" : "square")
                            .font(.title)
                            .padding(0)
                            .frame(minWidth: 0, maxWidth: .infinity)
                            
                    }
                    
                    //.frame(width: (geo.size.width * 0.65) / CGFloat(choiceNumber.count), alignment: .center)
                    .frame(width: (width * 0.65) / CGFloat(choiceNumber.count), alignment: .center)
                    
                }
            }
            .background(index % 2 == 0 ? .clear : alternatingRowColor)
        } else {
            let (choiceNumber, _) = parseSelectChoicesOrCalculations(field: field.wrappedValue)
            HStack(spacing: 0) {
                QuestionLabel(field: field)

                ForEach(0..<choiceNumber.count, id: \.self) { optionIndex in
                    Button(action: {
                        field.wrappedValue.answer = String(choiceNumber[optionIndex])
                        field.wrappedValue.updated = true
                    }) {
                        Image(systemName: field.wrappedValue.answer == String(choiceNumber[optionIndex]) ? "checkmark.square" : "square")
                            .font(.title)
                            .padding(0)
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .zIndex(0)
                    }
                    
                    //.frame(width: (geo.size.width * 0.65) / CGFloat(choiceNumber.count), alignment: .center)
                    .frame(width: (width * 0.65) / CGFloat(choiceNumber.count), alignment: .center)
                }
            }
            .background(index % 2 == 0 ? .clear : alternatingRowColor)
        }
    }
    
    //MARK: - RadioButtons
    @ViewBuilder
    func
    RadioButtons(field: Binding<RCField>,index: Int,width:CGFloat) -> some View {
        let (choiceNumber,choiceLabels) = parseSelectChoicesOrCalculations(field: field.wrappedValue)
        HStack(spacing: 0) {
            QuestionLabel(field: field)

            VStack(spacing:15){
                ForEach(0..<choiceNumber.count, id: \.self) { optionIndex in
                    Button(action:{
                        field.wrappedValue.answer = String(choiceNumber[optionIndex])
                        field.wrappedValue.updated = true
                    }){
                        Text(choiceLabels[optionIndex])
                            .foregroundStyle(field.wrappedValue.answer == String(choiceNumber[optionIndex]) ? .white : .accentColor)
                            .font(.headline)
                            .bold()
                            .padding(10)
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(field.wrappedValue.answer == String(choiceNumber[optionIndex]) ? Color.accentColor : Color.clear)
                                            .overlay(content: {
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(Color.accentColor)
                                            })
                                          
                                      )
                            
                    }
                }
                .frame(width: 300)
            }
            //.frame(width: (geo.size.width * 0.65), alignment: .center)
            .frame(width: (width * 0.65), alignment: .center)
        }
        .padding(.vertical,25)
        .background(index % 2 == 0 ? .clear : alternatingRowColor)
    }
    
    @ViewBuilder
    func
    MatrixHeaderView(field: Binding<RCField>,index: Int, width:CGFloat) -> some View {
        let (choiceNumber,choiceLabels) = parseSelectChoicesOrCalculations(field: field.wrappedValue)
        
        
        VStack(spacing: 0) {
            // Header
            HStack{
                HStack(spacing:0) {
                    Spacer()
                        .background(.gray.opacity(0.5))
                        .frame(minWidth: 0, maxWidth: .infinity)
                        
                    ForEach(choiceLabels, id: \.self) { label in
                        Text(label)
                            .foregroundStyle(.white)
                            .font(.title)
                            .bold()
                            .frame(minWidth: 0, maxWidth: .infinity)
                            
                            
                        
                    }
                    .onAppear{
                        print(choiceLabels)
                    }

                    //.frame(width: (geo.size.width * 0.65) / CGFloat(choiceNumber.count), alignment: .center)
                    .frame(width: (width * 0.65) / CGFloat(choiceNumber.count), alignment: .center)
                    
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(Color.accentColor)
            //.zIndex(.infinity)
            .sticky()
        
            RadioButtonCheckboxes(field: field, cNumber: choiceNumber,index:index,width: width)
                .zIndex(.leastNonzeroMagnitude)
                
        }
        
    }
    
    
    //MARK: - Matrix RadioView
    @ViewBuilder
    func
    MatrixRadioView(field: Binding<RCField>, newMatrix: Bool,labelSpace:Float = 0.25,index:Int,width:CGFloat) -> some View{
        if newMatrix {
//            Text("new Matrix: \(field.wrappedValue.matrixGroupName ?? "")")
            MatrixHeaderView(field: field,index:index,width: width)
                .zIndex(.infinity)
            //                  Header
            //                      .sticky
            //                  Radiobuttons
            
        }else{
            RadioButtonCheckboxes(field: field, index:index,width: width)
                .zIndex(.leastNonzeroMagnitude)
        }
        
    }

    @ViewBuilder
    func RCItemView(field: Binding<RCField>,width: CGFloat) -> some View {
        let index = self.surveyItems.firstIndex(where: { $0.fieldName == field.wrappedValue.fieldName })!
        switch field.wrappedValue.fieldType {
        case .text:
            RCTextFieldView(field: field, index: index,width:width)
        case .notes:
            Text("notes")
        case .calc:
            Text("calc")
        case .dropdown:
            Text("dropdown")
        case .radio:
            //check if there is a matrixHeader
            if field.matrixGroupName.wrappedValue != ""{
                //Check if this field is part of a matrix by looking at header
                //Check if it's a new Matrix by looking up its index in the fields array and run the check with the array extension
                let isStartOfNewGroup = self.surveyItems.isStartOfNewMatrixGroup(at: index)
                MatrixRadioView(field: field, newMatrix: isStartOfNewGroup,index:index,width:width)
            }else{
                RadioButtons(field: field, index: index,width:width)
            }
           
        case .checkbox:
            Text(field.fieldLabel.wrappedValue ?? "")
        case .yesno:
            Text("yesno")
        case .truefalse:
            Text("truefalse")
        case .file:
            Text("file")
        case .slider:
            Text("slider")
        case .descriptive:
            Text("descriptive")
        case .sql:
            Text("sql")
        }
        
    }
    
    //MARK: - Functions
    //Branching evaluation
    
    //parse radio options, returns a touple containing both arrays
    private func parseSelectChoicesOrCalculations(field: RCField)->(ChoiceNumber:[String],ChoiceLabel:[String]){
        guard field.selectChoicesOrCalculations != nil,
              let choiceString = field.selectChoicesOrCalculations else {
            print("no options")
            return ([],[])
        }
        let filtered = choiceString
            .filter { !$0.isWhitespace}
            .components(separatedBy: "|")
        var choiceNumber: [String] = []
        var ChoiceLabel: [String] = []
        for element in filtered {
            let values = element.components(separatedBy: ",")
            choiceNumber.append(values[0])
            ChoiceLabel.append(values[1])
        }
        return (choiceNumber,ChoiceLabel)
    }
    
    
    
    private func evaluateBranching(field: RCField, surveyItems: [RCField]) -> Bool {
        // show all Fields that have no branching logic
        guard (field.branchingLogic != "") else {return true}
        
        print(field.branchingLogic!)
        //Pattern Matching, Not including possible Brackets Yet
        let regex = Regex {
            //name
            "["
            Capture{
                OneOrMore{
                    CharacterClass("a"..."z", "A"..."Z", "0"..."9")
                }
            }
            Optionally{
                "("
                Capture{
                    OneOrMore(.digit)
                }
                ")"
            }
            "]"
            //operator
            Capture {
                ChoiceOf{
                    "<>"
                    ">"
                    "<"
                    "="
                }
            }
            
            Optionally("\"")
            Capture {
                ChoiceOf{
                    OneOrMore(.digit)
                    ZeroOrMore{
                        CharacterClass("a"..."z", "A"..."Z", "0"..."9")
                    }
                }
            }
            Optionally("\"")
            Optionally(
                Capture {
                    ChoiceOf{
                        "or"
                        "and"
                    }
                })
        }
        
        let matches = field.branchingLogic!
            .replacingOccurrences(of: " ", with: "")
            .matches(of: regex).map {match in
            RCBranchingLogic(fieldName: String(match.1),checkboxNumber: String(match.2 ?? "-1"), op: String(match.3), right: String(match.4), concat: String(match.5 ?? ""))
        }
        print(matches)
        
        func evaluateBranching(rcItems: [RCField], branchingLogic: [RCBranchingLogic])->Bool {
            var evals: [Bool] = []
            for logic in branchingLogic {
                guard let answer = (rcItems.filter{$0.fieldName == logic.fieldName}.first?.answer) else{
                    print("no answer found")
                    evals.append(false)
                    return false
                }
                switch logic.op {
                case ">":
                    guard let right = Int(logic.right),
                          let left = Int(answer) else {
                        print("no number")
                        evals.append(false)
                        return false
                    }
                    if left > right {
                        evals.append(true)
                    }else{
                        evals.append(false)
                    }
                case "<":
                    guard let right = Int(logic.right),
                          let left = Int(answer) else {
                        print("no number")
                        evals.append(false)
                        return false
                    }
                    if left < right {
                        evals.append(true)
                    }else{
                        evals.append(false)
                    }
                case "<>":
                    if answer != "" {
                        evals.append(true)
                    }else{
                        evals.append(false)
                    }
                case "=":
                    if answer == logic.right {
                        evals.append(true)
                    }else{
                        evals.append(false)
                    }
                default:
                    break
                }
            }
            
            print(evals)
            
            let concats = branchingLogic
                .map { e in
                    e.concat}
                .filter {$0 != "" }
            
            //sort so that or comes first, returns the indicies
            
            let sortedIndices = concats.enumerated().sorted {
                let str1 = $0.element
                let str2 = $1.element
                switch (str1, str2) {
                    case ("or", _): return true
                    case (_, "or"): return false
                    case ("and", _): return false
                    case (_, "and"): return true
                    default: return $0.offset < $1.offset
                }
            }
            
            //print(sortedIndices)
            
            // Work from inside out, start with the or. Pop the i+1 and set the pair to the result. Then do the and. return the result.
            
                for (i,conc) in sortedIndices {
                    switch conc {
                    case "and":
                        if evals[i] && evals[i+1]{
                            evals.remove(at: i+1)
                            evals[i] = true
                        } else {
                            evals.remove(at: i+1)
                            evals[i] = false
                        }
                    case "or":
                        if evals[i] || evals[i+1]{
                            evals.remove(at: i+1)
                            evals[i] = true
                            
                        } else {
                            evals.remove(at: i+1)
                            evals[i] = false
                        }
                    default:
                        break
                    }
                }
            return evals.first ?? false
            //return !result.contains(false)
        }

        let t = evaluateBranching(rcItems: surveyItems, branchingLogic: matches)
        print(t)
        return t
    }
    
}

extension RCFormView {
    var jsonData: Data? { return """
    [{"field_name":"t1","form_name":"test","section_header":"","field_type":"text","field_label":"true?","select_choices_or_calculations":"","field_note":"","text_validation_type_or_show_slider_number":"","text_validation_min":"","text_validation_max":"","identifier":"","branching_logic":"","required_field":"","custom_alignment":"","question_number":"","matrix_group_name":"","matrix_ranking":"","field_annotation":""}, {"field_name":"t2","form_name":"test","section_header":"","field_type":"notes","field_label":"t2","select_choices_or_calculations":"","field_note":"","text_validation_type_or_show_slider_number":"","text_validation_min":"","text_validation_max":"","identifier":"","branching_logic":"","required_field":"","custom_alignment":"","question_number":"","matrix_group_name":"","matrix_ranking":"","field_annotation":""}, {"field_name":"t3","form_name":"test","section_header":"","field_type":"calc","field_label":"t3","select_choices_or_calculations":"","field_note":"","text_validation_type_or_show_slider_number":"","text_validation_min":"","text_validation_max":"","identifier":"","branching_logic":"","required_field":"","custom_alignment":"","question_number":"","matrix_group_name":"","matrix_ranking":"","field_annotation":""}, {"field_name":"t4","form_name":"test","section_header":"","field_type":"dropdown","field_label":"t4","select_choices_or_calculations":"1, one | 2, two | 3, three | 4, four | 5, five","field_note":"","text_validation_type_or_show_slider_number":"","text_validation_min":"","text_validation_max":"","identifier":"","branching_logic":"","required_field":"","custom_alignment":"","question_number":"","matrix_group_name":"","matrix_ranking":"","field_annotation":""}, {"field_name":"t5","form_name":"test","section_header":"","field_type":"radio","field_label":"t5","select_choices_or_calculations":"1, one | 2, two | 3, three | 4, four | 5, five","field_note":"","text_validation_type_or_show_slider_number":"","text_validation_min":"","text_validation_max":"","identifier":"","branching_logic":"","required_field":"","custom_alignment":"","question_number":"","matrix_group_name":"","matrix_ranking":"","field_annotation":""},
        {"field_name":"t5_1","form_name":"test","section_header":"","field_type":"checkbox","field_label":"t5","select_choices_or_calculations":"1, one | 2, two | 3, three | 4, four | 5, five","field_note":"","text_validation_type_or_show_slider_number":"","text_validation_min":"","text_validation_max":"","identifier":"","branching_logic":"","required_field":"","custom_alignment":"","question_number":"","matrix_group_name":"","matrix_ranking":"","field_annotation":""},
        {"field_name":"t5_2","form_name":"test","section_header":"","field_type":"text","field_label":"true?","select_choices_or_calculations":"","field_note":"","text_validation_type_or_show_slider_number":"","text_validation_min":"","text_validation_max":"","identifier":"","branching_logic":"[t1] = \\"Hallo\\" ","required_field":"","custom_alignment":"","question_number":"","matrix_group_name":"","matrix_ranking":"","field_annotation":""},{"field_name":"t6","form_name":"test","section_header":"","field_type":"yesno","field_label":"t6","select_choices_or_calculations":"","field_note":"","text_validation_type_or_show_slider_number":"","text_validation_min":"","text_validation_max":"","identifier":"","branching_logic":"","required_field":"","custom_alignment":"","question_number":"","matrix_group_name":"","matrix_ranking":"","field_annotation":""}, {"field_name":"t7","form_name":"test","section_header":"","field_type":"truefalse","field_label":"t7","select_choices_or_calculations":"","field_note":"","text_validation_type_or_show_slider_number":"","text_validation_min":"","text_validation_max":"","identifier":"","branching_logic":"","required_field":"","custom_alignment":"","question_number":"","matrix_group_name":"","matrix_ranking":"","field_annotation":""}, {"field_name":"t8","form_name":"test","section_header":"","field_type":"file","field_label":"t8","select_choices_or_calculations":"","field_note":"","text_validation_type_or_show_slider_number":"signature","text_validation_min":"","text_validation_max":"","identifier":"","branching_logic":"","required_field":"","custom_alignment":"","question_number":"","matrix_group_name":"","matrix_ranking":"","field_annotation":""}, {"field_name":"t9","form_name":"test","section_header":"","field_type":"file","field_label":"t9","select_choices_or_calculations":"","field_note":"","text_validation_type_or_show_slider_number":"","text_validation_min":"","text_validation_max":"","identifier":"","branching_logic":"","required_field":"","custom_alignment":"","question_number":"","matrix_group_name":"","matrix_ranking":"","field_annotation":""}, {"field_name":"t10","form_name":"test","section_header":"","field_type":"slider","field_label":"t10","select_choices_or_calculations":"left label | middel label | right label","field_note":"","text_validation_type_or_show_slider_number":"number","text_validation_min":"","text_validation_max":"","identifier":"","branching_logic":"","required_field":"","custom_alignment":"RH","question_number":"","matrix_group_name":"","matrix_ranking":"","field_annotation":""}, {"field_name":"t11","form_name":"test","section_header":"","field_type":"descriptive","field_label":"t11","select_choices_or_calculations":"","field_note":"","text_validation_type_or_show_slider_number":"","text_validation_min":"","text_validation_max":"","identifier":"","branching_logic":"","required_field":"","custom_alignment":"","question_number":"","matrix_group_name":"","matrix_ranking":"","field_annotation":""}, {"field_name":"t12","form_name":"test","section_header":"section","field_type":"sql","field_label":"t12","select_choices_or_calculations":"","field_note":"","text_validation_type_or_show_slider_number":"","text_validation_min":"","text_validation_max":"","identifier":"","branching_logic":"","required_field":"","custom_alignment":"RH","question_number":"","matrix_group_name":"","matrix_ranking":"","field_annotation":""}]
    """
        .data(using: .utf8)
    }
}

#Preview {
    NavigationStack{
        RCFormView()
    }
}
