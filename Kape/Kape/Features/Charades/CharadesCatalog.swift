import Foundation

/// A separate, free starter set; original decks and purchase identifiers are preserved.
enum CharadesCatalog {
    static let starter = Deck(
        id: "pantomime", title: "Për me fillu", description: "Veprime e kafshë për me hy n’lojë.",
        iconName: "theatermasks", difficulty: 1, isPro: false,
        cards: [
            "Me notu", "Boks", "Me vrapu", "Me lujt valle", "Me zanë peshk", "Me gatu", "Me këndu", "Futboll",
            "Basketboll", "Tenis", "Me bo ski", "Me bo patinazh", "Me ngas biçikletën", "Me kalëru", "Me u ngjit n’mal",
            "Me i la dhambët", "Me i kreh flokët", "Me i lidh patikat",
            "Me hap ombrellën", "Me i la duart", "Me pi ujë", "Me hangër bananë",
            "Me pre bukë", "Me fshi patosin", "Me la sudet", "Me i hekurosë teshat",
            "Me mbjellë një dru", "Me ngas veturën", "Me bo foto",
            "Me lexu libër", "Me shkru letër", "Me i ra kitarës",
            "Me i ra pianos", "Me i ra lodrës", "Me hap dhuratën",
            "Me fry balonin", "Me mbajt bebën", "Me ec n’litar",
            "Me ngrit pesha", "Me kërcy me litar", "Qeni", "Macja", "Luani", "Elefanti",
            "Majmuni", "Lepuri", "Gjarpni", "Bretkosa", "Pinguini", "Pula", "Kali", "Ariu",
            "Flutura", "Zogu", "Roboti", "Kamarieri", "Berberi", "Dirigjenti", "Me fjetë",
            "Teshtima", "Selfie", "Me bo TikTok", "Me skrollu n’telefon",
            "Mesazhi me zë"
        ].enumerated().map { Card(id: "pantomime-\($0.offset + 1)", text: $0.element) }
    )
}
