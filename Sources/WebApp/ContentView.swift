import CatAPI
import ElementaryUI

@View
struct ContentView {
    @State var facts: [String] = []
    @State var error: String? = nil

    var body: some View {
        h1 { "Cat Facts" }

        button {
            "Fetch Random Fact"
        }.onClick {
            Task {
                await fetchRandomFact()
            }
        }

        if let error = error {
            p { "Error: \(error)" }
        }

        if let fact = facts.last {
            p { b { "\(fact)" } }
        }

        p {
            for oldFact in facts.dropLast(1) {
                i { "\(oldFact)" }
                br()
                br()
            }
        }
    }

    func fetchRandomFact() async {
        self.error = nil

        let client = Client(
            serverURL: .init(string: "https://catfact.ninja")!,
            transport: JSFetchClientTransport()
        )

        do {
            guard let fact = try await client.getRandomFact().ok.body.json.fact else {
                return
            }

            facts.append(fact)
        } catch {
            self.error = "\(error)"
        }
    }
}
