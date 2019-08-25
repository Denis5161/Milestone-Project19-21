//
//  DetailViewController.swift
//  Milestone Project19-21
//
//  Created by Denis Goldberg on 22.08.19.
//  Copyright © 2019 Denis Goldberg. All rights reserved.
//

import UIKit

protocol NoteHandlingDelegate {
    func createNewNote()
    func save(_ note: Note, at index: Int)
    func delete(_ note: Note, at index: Int)
}

class DetailViewController: UIViewController, UITextViewDelegate {
    var currentNote: Note?
    var notesIndex: Int?
    
    var shareButtonIndex = 0
    let done = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneTapped))
    
    var noteHandlingDelegate: NoteHandlingDelegate!
    
    
    @IBOutlet var contentInput: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
    }
    
    func setupView() {
//        Set the title
        navigationItem.largeTitleDisplayMode = .never
        title = currentNote?.name
        
//        Load text into the contentInput View
        contentInput.text = currentNote?.content
        
//        Toolbar items
        let delete = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(deleteTapped))
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let compose = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(composeTapped))
        
        toolbarItems = [delete, spacer, compose]
        navigationController?.isToolbarHidden = false
        
//        Navigation Bar buttons
        let share = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareTapped))
        navigationItem.rightBarButtonItem = share
        
//        Set View as UITextViewDelegate
        contentInput.delegate = self
        
//        Keyboard notifications
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    //    MARK: - Navigation Bar Functions
    @objc func shareTapped() {
        guard let note = currentNote else {
            print("Error sharing note")
            return
        }
        let sharedNote = "Note Title: \(note.name)\n\(note.content)"
        let vc = UIActivityViewController(activityItems: [sharedNote], applicationActivities: [])
        vc.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItems?[shareButtonIndex] ?? navigationItem.rightBarButtonItem
        present(vc, animated: true)
    }
    
    @objc func doneTapped() {
        view.endEditing(true)
    }
    
    //    MARK: - Toolbar item Functions
    @objc func deleteTapped() {
        guard let note = currentNote, let index = notesIndex else { return }
        navigationController?.popViewController(animated: true)
        noteHandlingDelegate.delete(note, at: index)
    }
    
    @objc func composeTapped() {
        navigationController?.popViewController(animated: true)
        noteHandlingDelegate.createNewNote()
    }
    
    //    MARK: - UITextView Delegate method
    func textViewDidChange(_ textView: UITextView) {
        currentNote?.content = contentInput.text
        currentNote?.dateModified = Date()
        guard let note = currentNote, let index = notesIndex else { return }
        noteHandlingDelegate.save(note, at: index)
        notesIndex = 0
    }
    
    //    MARK: - Keyboard notifications
    @objc func adjustForKeyboard(notification: Notification) {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        
        let keyboardScreenEndFrame = keyboardValue.cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)
        if notification.name == UIResponder.keyboardWillHideNotification {
            contentInput.contentInset = .zero
            navigationItem.rightBarButtonItems?.removeAll { $0 == done }
            shareButtonIndex = 0
        } else {
            contentInput.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height - view.safeAreaInsets.bottom, right: 0)
            navigationItem.rightBarButtonItems?.insert(done, at: 0)
            shareButtonIndex = 1
        }
        
        contentInput.scrollIndicatorInsets = contentInput.contentInset
        
        let selectedRange = contentInput.selectedRange
        contentInput.scrollRangeToVisible(selectedRange)
    }
    
}
