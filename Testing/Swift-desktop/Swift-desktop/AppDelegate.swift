import Cocoa
import YapDatabase


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

	func applicationDidFinishLaunching(_ aNotification: Notification) {
		self.testDatabase()
//		self.testUpgrade()
	}
	
	private func testDatabase() {
		
		let baseDirs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
		let baseDir = baseDirs[0]

		let databaseURL = baseDir.appendingPathComponent("database.sqlite")

		let database = YapDatabase(url: databaseURL)
        database?.register(YapDatabaseRelationship(), withName: "relationship")
        
        database?.registerCodableSerialization(List.self, forCollection: kCollection_List)
        database?.registerCodableSerialization(A.self, forCollection: "A")
        database?.registerCodableSerialization(B.self, forCollection: "B")

        let config = YapDatabaseConnectionConfig()
        config.objectCacheEnabled = false
        let databaseConnection = database?.newConnection(config)
//		let uuid = "fobar"
//
//		databaseConnection?.asyncReadWrite({ (transaction) in
//
//			let list = List(uuid: uuid, title: "Groceries")
//			transaction.setObject(list, forKey: list.uuid, inCollection: kCollection_List)
//		})
//
//		databaseConnection?.asyncRead({ (transaction) in
//
//			if let list: List = transaction.object(forKey: uuid, inCollection: kCollection_List) as? List {
//				print("Read list: \(list.title)")
//			} else {
//				print("wtf")
//			}
//
//			transaction.iterateCollections { (collection, stop) in
//
//				print("row: collection: \(collection)")
//			}
//
//			transaction.iterateKeys(inCollection: kCollection_List) { (key, stop) in
//
//				print("row: key: \(key)")
//			}
//
//			transaction.iterateKeysAndObjects(inCollection: kCollection_List) { (key, list: List, stop) in
//
//				print("Iterate list: \(list.title)")
//			}
//		})
        
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
}
