import CoreData

/// The Core Data schema, built programmatically rather than in a
/// `.xcdatamodeld` file. Two small, stable entities don't need the model
/// editor's overhead, and a programmatic model is trivially reviewable as
/// plain Swift.
enum CoreDataModel {
    static let model: NSManagedObjectModel = {
        let model = NSManagedObjectModel()
        model.entities = [favoriteEntity, orderEntity]
        return model
    }()

    private static let favoriteEntity: NSEntityDescription = {
        let entity = NSEntityDescription()
        entity.name = "FavoriteEntity"
        entity.managedObjectClassName = NSStringFromClass(FavoriteEntity.self)

        let productId = attribute("productId", .integer64AttributeType)
        let title = attribute("title", .stringAttributeType)
        let category = attribute("category", .stringAttributeType)
        let price = attribute("price", .doubleAttributeType)
        let rating = attribute("rating", .doubleAttributeType)
        let thumbnailURLString = attribute("thumbnailURLString", .stringAttributeType, isOptional: true)
        let addedAt = attribute("addedAt", .dateAttributeType)

        entity.properties = [productId, title, category, price, rating, thumbnailURLString, addedAt]
        entity.uniquenessConstraints = [["productId"]]
        return entity
    }()

    private static let orderEntity: NSEntityDescription = {
        let entity = NSEntityDescription()
        entity.name = "OrderEntity"
        entity.managedObjectClassName = NSStringFromClass(OrderEntity.self)

        entity.properties = [
            attribute("id", .UUIDAttributeType),
            attribute("productId", .integer64AttributeType),
            attribute("productTitle", .stringAttributeType),
            attribute("productThumbnailURLString", .stringAttributeType, isOptional: true),
            attribute("quantity", .integer64AttributeType),
            attribute("unitPrice", .doubleAttributeType),
            attribute("subtotal", .doubleAttributeType),
            attribute("serviceFee", .doubleAttributeType),
            attribute("total", .doubleAttributeType),
            attribute("createdAt", .dateAttributeType)
        ]
        entity.uniquenessConstraints = [["id"]]
        return entity
    }()

    private static func attribute(
        _ name: String,
        _ type: NSAttributeType,
        isOptional: Bool = false
    ) -> NSAttributeDescription {
        let attribute = NSAttributeDescription()
        attribute.name = name
        attribute.attributeType = type
        attribute.isOptional = isOptional
        return attribute
    }
}
