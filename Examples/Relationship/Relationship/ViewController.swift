/*
 * Copyright (C) 2015 - 2016, Daniel Dahan and CosmicMind, Inc. <http://cosmicmind.io>.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *	*	Redistributions of source code must retain the above copyright notice, this
 *		list of conditions and the following disclaimer.
 *
 *	*	Redistributions in binary form must reproduce the above copyright notice,
 *		this list of conditions and the following disclaimer in the documentation
 *		and/or other materials provided with the distribution.
 *
 *	*	Neither the name of CosmicMind nor the names of its
 *		contributors may be used to endorse or promote products derived from
 *		this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/*
The following ViewController exemplifies the usage of Relationships. 
In this example, there are Person and Company Entity types that are 
related through an Employee Relationship.

For example:	Person is an Employee of Company.

Person is the sbject of the Relationship.
Employee is the Relationship type.
Company is the object of the Relationship.
*/

import UIKit
import Graph

class ViewController: UIViewController {
	/// Access the Graph persistence layer.
	private lazy var graph = Graph()
	
	/// A tableView used to display Relationship entries.
	private let tableView = UITableView()
	
	/// A list of all the Employee Relationships.
	private var employees = [Relationship]()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		prepareGraph()
		prepareEmployees()
		prepareTableView()
		prepareNavigationBarItems()
	}
	
	/// Handles the add button event.
	internal func handleAddButton(sender: UIBarButtonItem) {
		// Create a Person Entity.
		let person = Entity(type: "Person")
		person["firstName"] = "First"
		person["lastName"] = "Last"
		person["photo"] = UIImage(contentsOfFile: NSBundle.mainBundle().pathForResource("Avatar", ofType: "png")!)
		
		// Create a Company Entity.
		let company = Entity(type: "Company")
		company["name"] = "Company"
		
		// Create an Employee Relationship.
		let employee: Relationship = Relationship(type: "Employee")
		
		// Form the relationship.
		employee.subject = person
		employee.object = company
		
        /*
         The graph.async call triggers an asynchronous callback
         that may be used for various benefits. As well, since
         the graph is watching Person Entities, the
         graphDidInsertEntity delegate method is executed once
         the save has completed.
         */
        graph.async { (success: Bool, error: NSError?) in
            if let e: NSError = error {
                print(e)
            }
        }
	}
	
	/// Prepares the Graph instance.
	private func prepareGraph() {
		/*
		Rather than searching the Employee Relationships on each
		insert, the Graph Watch API is used to update the
		employees Array. This allows a single search query to be
		made when loading the ViewController.
		*/
		graph.delegate = self
		graph.watchForRelationship(types: ["Employee"])
	}
	
	/// Prepares the employees Array.
	private func prepareEmployees() {
		employees = graph.searchForRelationship(types: ["Employee"])
		
		// Add Employee Relationships if none exist.
		if 0 == employees.count {
			// Create Person Entities.
			let tim = Entity(type: "Person")
			tim["firstName"] = "Tim"
			tim["lastName"] = "Cook"
			tim["photo"] = UIImage(contentsOfFile: NSBundle.mainBundle().pathForResource("TimCook", ofType: "png")!)
			
			let mark = Entity(type: "Person")
			mark["firstName"] = "Mark"
			mark["lastName"] = "Zuckerberg"
			mark["photo"] = UIImage(contentsOfFile: NSBundle.mainBundle().pathForResource("MarkZuckerberg", ofType: "png")!)
			
			let elon = Entity(type: "Person")
			elon["firstName"] = "Elon"
			elon["lastName"] = "Musk"
			elon["photo"] = UIImage(contentsOfFile: NSBundle.mainBundle().pathForResource("ElonMusk", ofType: "png")!)
			
			// Create Company Entities.
			let apple = Entity(type: "Company")
			apple["name"] = "Apple"
			
			let facebook = Entity(type: "Company")
			facebook["name"] = "Facebook"
			
			let tesla = Entity(type: "Company")
			tesla["name"] = "Tesla Motors"
			
			// Create Employee Relationships.
			let employee1 = Relationship(type: "Employee")
			let employee2 = Relationship(type: "Employee")
			let employee3 = Relationship(type: "Employee")
			
			// Form relationships.
			employee1.subject = tim
			employee1.object = apple
			
			employee2.subject = mark
			employee2.object = facebook
			
			employee3.subject = elon
			employee3.object = tesla
			
            /*
             The graph.async call triggers an asynchronous callback
             that may be used for various benefits. As well, since
             the graph is watching Person Entities, the
             graphDidInsertEntity delegate method is executed once
             the save has completed.
             */
            graph.async { (success: Bool, error: NSError?) in
                if let e: NSError = error {
                    print(e)
                }
            }
		}
	}
	
	/// Prepares the tableView.
	private func prepareTableView() {
		tableView.frame = view.bounds
		tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "Cell")
		tableView.dataSource = self
		tableView.delegate = self
		view.addSubview(tableView)
	}
	
	/// Prepares the navigation bar items.
	private func prepareNavigationBarItems() {
		navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: #selector(handleAddButton(_:)))
	}
}

/// GraphDelegate delegation methods.
extension ViewController: GraphDelegate {
	/// GraphDelegate delegation method that is executed on Relationship inserts.
    func graphDidInsertRelationship(graph: Graph, relationship: Relationship, fromCloud: Bool) {
		employees.append(relationship)
		tableView.reloadData()
	}
}


/// TableViewDataSource methods.
extension ViewController: UITableViewDataSource {
	/// Determines the number of rows in the tableView.
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return employees.count
	}
	
	/// Returns the number of sections.
	func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return 1
	}
	
	/// Prepares the cells within the tableView.
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = UITableViewCell(style: .Subtitle, reuseIdentifier: "Cell")
		
		// Get the Relationship.
		let employee = employees[indexPath.row]
		
		// Set the Person details.
		if let person = employee.subject {
			cell.textLabel?.text = (person["firstName"] as! String) + " " + (person["lastName"] as! String)
			cell.imageView?.image = person["photo"] as? UIImage
		}
		
		// Set the Company details.
		if let company = employee.object {
			cell.detailTextLabel?.text = "Works At: " + (company["name"] as! String)
		}
		
		return cell
	}
	
	/// Prepares the header within the tableView.
	func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		let header = UIView(frame: CGRectMake(0, 0, view.bounds.width, 48))
		header.backgroundColor = .whiteColor()
		
		let label = UILabel(frame: CGRectMake(16, 0, view.bounds.width - 32, 48))
		label.textColor = .grayColor()
		label.text = "Employees"
		
		header.addSubview(label)
		return header
	}
}

/// UITableViewDelegate methods.
extension ViewController: UITableViewDelegate {
	/// Sets the tableView cell height.
	func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
		return 80
	}
	
	/// Sets the tableView header height.
	func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		return 48
	}
}
