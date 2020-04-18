import Cocoa
import YapDatabase


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

	func applicationDidFinishLaunching(_ aNotification: Notification) {
	//	testDatabase()
	//	testUpgrade()
		testIssue515()
//        testIssue515_A_B()
	}
	
	private func testDatabase() {
		
		let baseDirs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
		let baseDir = baseDirs[0]

		let databaseURL = baseDir.appendingPathComponent("database.sqlite")

		let database = YapDatabase(url: databaseURL)
		database?.registerCodableSerialization(List.self, forCollection: kCollection_List)

		let databaseConnection = database?.newConnection()
		let uuid = "fobar"

		databaseConnection?.asyncReadWrite({ (transaction) in

			let list = List(uuid: uuid, title: "Groceries")
			transaction.setObject(list, forKey: list.uuid, inCollection: kCollection_List)
		})

		databaseConnection?.asyncRead({ (transaction) in

			if let list: List = transaction.object(forKey: uuid, inCollection: kCollection_List) as? List {
				print("Read list: \(list.title)")
			} else {
				print("wtf")
			}

			transaction.iterateCollections { (collection, stop) in

				print("row: collection: \(collection)")
			}

			transaction.iterateKeys(inCollection: kCollection_List) { (key, stop) in

				print("row: key: \(key)")
			}

			transaction.iterateKeysAndObjects(inCollection: kCollection_List) { (key, list: List, stop) in

				print("Iterate list: \(list.title)")
			}
		})
	}
	
	private func testUpgrade() {
		
		let baseDirs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
		let baseDir = baseDirs[0]

		let databaseURL = baseDir.appendingPathComponent("database.sqlite")

		let database = YapDatabase(url: databaseURL)
		database?.registerCodableSerialization(Foobar.self, forCollection: "upgrade")

		let databaseConnection = database?.newConnection()
		
//		databaseConnection?.asyncReadWrite { (transaction) in
//
//			let foobar = Foobar(name: "Fancy Pants")
//			transaction.setObject(foobar, forKey: "1", inCollection: "upgrade")
//		}
		
		databaseConnection?.asyncRead {(transaction) in
			
			if let foobar = transaction.object(forKey: "1", inCollection: "upgrade") as? Foobar {
				print("read foobar: name(\(foobar.name)) age(\(foobar.age))")
			}
			else {
				print("no foobar for you")
			}
		}
	}
	
	private func testIssue515() {
		let baseDirs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
		let baseDir = baseDirs[0]
		let databaseURL = baseDir.appendingPathComponent("database.sqlite")
		
		let database = YapDatabase(url: databaseURL)
		
		let collection = "issue515"
		database?.registerCodableSerialization(Issue515.self, forCollection: collection)
		
		let ext = YapDatabaseRelationship()
		database?.register(ext, withName: "relationships")
		
		let databaseConnection = database?.newConnection()
		
		databaseConnection?.asyncReadWrite {(transaction) in
			
			let test = Issue515(foobar: 42)
			
			transaction.setObject(test, forKey: "key", inCollection: collection)
		}
	}
    
    private func testIssue515_A_B() {
        let baseDirs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let baseDir = baseDirs[0]
        
        let databaseURL = baseDir.appendingPathComponent("database.sqlite")
        print("databaseURL: \(databaseURL.absoluteString)")
        
        let database = YapDatabase(url: databaseURL)
        database?.register(YapDatabaseRelationship(), withName: "relationship")
        
        database?.registerCodableSerialization(List.self, forCollection: kCollection_List)
        database?.registerCodableSerialization(A.self, forCollection: "A")
        database?.registerCodableSerialization(B.self, forCollection: "B")
        
        let config = YapDatabaseConnectionConfig()
        config.objectCacheEnabled = false
        let databaseConnection = database?.newConnection(config)
        
        
        let a = A(id: UUID(), name: "I'm a")
        let b = B(id: UUID(), aID: a.id, text: "I'm b")
        
        databaseConnection?.readWrite({ tx in
            tx.setObject(a, forKey: a.id.uuidString, inCollection: "A")
            tx.setObject(b, forKey: b.id.uuidString, inCollection: "B")
        })
        
        databaseConnection?.read({ tx in
            guard let fetched = tx.object(forKey: a.id.uuidString, inCollection: "A") as? A else { return }
            print("fetched A: \(fetched)")
            
            guard let vtx = tx.ext("relationship") as? YapDatabaseRelationshipTransaction else {
                return
            }
            print("vtx: \(vtx)")
            vtx.enumerateEdges(withName: "B->A") { (edge, stop) in
                print("edge: \(edge)")
            }
        })
    }
}

struct A: Codable {
    let id: UUID
    let name: String
}

struct B: Codable {
    let id: UUID
    let aID: UUID
    let text: String
}

extension B: YapDatabaseRelationshipNode {
    public func yapDatabaseRelationshipEdges() -> [YapDatabaseRelationshipEdge]? {
        [YapDatabaseRelationshipEdge(
            name: "B->A",
            sourceKey: id.uuidString,
            collection: "B",
            destinationKey: aID.uuidString,
            collection: "A",
            nodeDeleteRules: .deleteSourceIfDestinationDeleted
        )]
    }
}
