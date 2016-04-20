//
//  CreateGistViewController.swift
//  grokSwiftREST
//
//  Created by Christina Moulton on 2016-04-20.
//  Copyright © 2016 Teak Mobile Inc. All rights reserved.
//

import Foundation
import XLForm

class CreateGistViewController: XLFormViewController {
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    self.initializeForm()
  }
  
  override init(nibName nibNameOrNil: String!, bundle nibBundleOrNil: NSBundle!) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    self.initializeForm()
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.navigationItem.leftBarButtonItem = UIBarButtonItem(
      barButtonSystemItem: UIBarButtonSystemItem.Cancel,
      target: self,
      action: #selector(cancelPressed(_:)))
    self.navigationItem.rightBarButtonItem = UIBarButtonItem(
      barButtonSystemItem: UIBarButtonSystemItem.Save,
      target: self,
      action: #selector(savePressed(_:)))
  }
  
  func cancelPressed(button: UIBarButtonItem) {
    self.navigationController?.popViewControllerAnimated(true)
  }
  
  func savePressed(button: UIBarButtonItem) {
    // TODO: implement
  }
  
  private func initializeForm() {
    let form = XLFormDescriptor(title: "Gist")
    
    // Section 1
    let section1 = XLFormSectionDescriptor.formSection() as XLFormSectionDescriptor
    form.addFormSection(section1)
    
    let descriptionRow = XLFormRowDescriptor(tag: "description", rowType:
      XLFormRowDescriptorTypeText, title: "Description")
    descriptionRow.required = true
    section1.addFormRow(descriptionRow)
    
    let isPublicRow = XLFormRowDescriptor(tag: "isPublic", rowType:
      XLFormRowDescriptorTypeBooleanSwitch, title: "Public?")
    isPublicRow.required = false
    section1.addFormRow(isPublicRow)
    
    let section2 = XLFormSectionDescriptor.formSectionWithTitle("File 1") as
    XLFormSectionDescriptor
    form.addFormSection(section2)
    
    let filenameRow = XLFormRowDescriptor(tag: "filename", rowType:
      XLFormRowDescriptorTypeText, title: "Filename")
    filenameRow.required = true
    section2.addFormRow(filenameRow)
    
    let fileContent = XLFormRowDescriptor(tag: "fileContent", rowType:
      XLFormRowDescriptorTypeTextView, title: "File Content")
    fileContent.required = true
    section2.addFormRow(fileContent)
    
    self.form = form
  }
}
