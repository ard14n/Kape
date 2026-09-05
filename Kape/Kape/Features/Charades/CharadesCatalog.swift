import Foundation

/// A separate, free starter set; original decks and purchase identifiers are preserved.
enum CharadesCatalog {
    static let starter = Deck(
        id: "pantomime", title: "Pantomimë", description: "Veprime dhe kafshë për t’u futur në lojë.",
        iconName: "theatermasks", difficulty: 1, isPro: false,
        cards: [
            "Not", "Boks", "Vrapim", "Vallëzim", "Peshkim", "Gatim", "Këndim", "Futboll",
            "Basketboll", "Tenis", "Ski", "Patinazh", "Çiklizëm", "Kalërim", "Ngjitje në mal",
            "Larja e dhëmbëve", "Krehja e flokëve", "Lidhja e këpucëve", "Hapja e një ombrelle",
            "Larja e duarve", "Pirja e ujit", "Ngrënia e një bananeje", "Prerja e bukës",
            "Fshirja e dyshemesë", "Larja e enëve", "Hekurosja e rrobave", "Mbjellja e një peme",
            "Drejtimi i makinës", "Bërja e një fotografie", "Leximi i një libri", "Shkrimi i një letre",
            "Luajtja në kitarë", "Luajtja në piano", "Luajtja në daulle", "Hapja e një dhurate",
            "Fryrja e një tullumbaceje", "Mbajtja e një foshnjeje", "Ecja në litar", "Ngritja e peshave",
            "Hedhja e litarit", "Qeni", "Macja", "Luani", "Elefanti", "Majmuni", "Lepuri",
            "Gjarpri", "Bretkosa", "Pinguini", "Pula", "Kali", "Ariu", "Flutura", "Zogu",
            "Roboti", "Kamarieri", "Berberi", "Dirigjenti", "Gjumi", "Teshtima"
        ].enumerated().map { Card(id: "pantomime-\($0.offset + 1)", text: $0.element) }
    )
}
