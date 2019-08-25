//
//  ViewController.swift
//  Milestone Project19-21
//
//  Created by Denis Goldberg on 22.08.19.
//  Copyright © 2019 Denis Goldberg. All rights reserved.
//

import UIKit

class ViewController: UITableViewController {
    
    var notes = [Note]()
    var filteredNotes = [Note]()
    let keyName = "notesJSON"
    
    let searchController = UISearchController(searchResultsController: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //        Set the navigation bar title
        navigationController?.navigationBar.prefersLargeTitles = true
        title = "Notes"
        
        
        //        Load the notes from UserDefaults
        loadNotes()
        
        //        Navigation Bar and Toolbaritems
        navigationItem.rightBarButtonItem = editButtonItem
        
        let addNoteItem = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(addNote))
        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        toolbarItems = [space, addNoteItem]
        navigationController?.isToolbarHidden = false
        
        //        Search Bar
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search"
        definesPresentationContext = true
        navigationItem.searchController = searchController
    }
    
    //    MARK: - TableView Cell setup
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFiltering() {
            return filteredNotes.count
        }
        return notes.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let noteName: String
        let noteModifiedDate: String
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        if isFiltering() {
            noteName = filteredNotes[indexPath.row].name
            noteModifiedDate = dateFormatter.string(from: filteredNotes[indexPath.row].dateModified)
        } else {
            noteName = notes[indexPath.row].name
            noteModifiedDate = dateFormatter.string(from: notes[indexPath.row].dateModified)
        }
        
        cell.textLabel?.text = noteName
        cell.detailTextLabel?.text = noteModifiedDate
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if isFiltering() {
                notes.removeAll { $0.name.contains(filteredNotes[indexPath.row].name) && $0.content.contains(filteredNotes[indexPath.row].content) }
                filteredNotes.remove(at: indexPath.row)
            } else {
                notes.remove(at: indexPath.row)
            }
            saveNotes()
            tableView.beginUpdates()
            tableView.deleteRows(at: [indexPath], with: .automatic)
            tableView.endUpdates()
        }
    }
    //    MARK: - Navigation
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        presentDetailView(atIndex: indexPath.row)
    }
    
    
    //    MARK: - Saving and Loading Data
    
    func loadNotes() {
        let defaults = UserDefaults.standard
        
        //        Try to access Data
        if let notesData = defaults.object(forKey: keyName) as? Data {
            //            Success! Decode the data
            let jsonDecoder = JSONDecoder()
            do {
                notes = try jsonDecoder.decode([Note].self, from: notesData)
                print("Loading Notes successful")
            } catch {
                print("There was a problem decoding notes array with the following error: \(error)")
            }
        }
    }
    
    func saveNotes() {
        let jsonEncoder = JSONEncoder()
        //        Encode Notes and then save to UserDefaults
        do {
            let encodedNotes = try jsonEncoder.encode(notes)
            
            let defaults = UserDefaults.standard
            defaults.set(encodedNotes, forKey: keyName)
            print("Save successful")
        } catch {
            print("There was a problem encoding notes array with the following error: \(error)")
        }
    }
    
    //    MARK: - Note Creation / Editing
    
    @objc func addNote() {
        //        Alert Controller, requesting a name for the note
        let ac = UIAlertController(title: "New Note", message: "Provide a name for your note", preferredStyle: .alert)
        ac.addTextField()
        ac.addAction(UIAlertAction(title: "Create", style: .default, handler: { [weak ac, weak self]_ in
            guard let text = ac?.textFields?[0].text else { return }
            if text.isEmpty || text == " " { return }
            
            //            Create new Note object and append to notes array
            self?.notes.insert(Note(name: text, content: "", dateModified: Date()), at: 0)
            self?.saveNotes()
            
            let indexPath = IndexPath(row: 0, section: 0)
            self?.tableView.insertRows(at: [indexPath], with: .automatic)
            
            self?.presentDetailView(atIndex: 0)
        }))
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(ac, animated: true)
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        // Takes care of toggling the button's title.
        super.setEditing(!isEditing, animated: true)
        
        tableView.setEditing(editing, animated: true)
    }
    
    //    MARK: - presentDetailView
    func presentDetailView(atIndex index: Int) {
        if let vc = storyboard?.instantiateViewController(withIdentifier: "Detail") as? DetailViewController {
            assert(!notes.isEmpty, "Notes array should not be empty!")
            vc.noteHandlingDelegate = self
            let selectedNote: Note
            let notesIndex: Int
            if isFiltering() {
                selectedNote = filteredNotes[index]
                notesIndex = notes.firstIndex(where: { $0.name == selectedNote.name && $0.content == selectedNote.content })!
            } else {
                selectedNote = notes[index]
                notesIndex = index
            }
            vc.currentNote = selectedNote
            vc.notesIndex = notesIndex
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
}
//MARK: - Note Handling Delegate
extension ViewController: NoteHandlingDelegate {
    func createNewNote() {
        addNote()
    }
    
    func delete(_ note: Note, at index: Int) {
        notes.remove(at: index)
        saveState()
    }
    
    func save(_ note: Note, at index: Int) {
        notes[index] = note
        notes.sort { $0.dateModified > $1.dateModified }
        saveState()
    }
    
    func saveState() {
        saveNotes()
        tableView.reloadData()
    }
    
}

//MARK: - Search Bar functionality
extension ViewController: UISearchResultsUpdating {
    
    
    func updateSearchResults(for searchController: UISearchController) {
        guard let text = searchController.searchBar.text else {
            filteredNotes = notes
            tableView.reloadData()
            return
        }
        filterContentForSearchText(text)
    }
    
    func searchBarIsEmpty() -> Bool {
        // Returns true if the text is empty or nil
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    func isFiltering() -> Bool {
        return searchController.isActive && !searchBarIsEmpty()
    }
    
    func filterContentForSearchText(_ searchText: String, scope: String = "All") {
        filteredNotes = notes.filter({ (Note) -> Bool in
            Note.name.lowercased().contains(searchText.lowercased()) || Note.content.lowercased().contains(searchText.lowercased())
        })
        tableView.reloadData()
    }
    
}
