import Combine
import SwiftUI
import CoreData

import GoogleGenerativeAI

struct ChatView: View {
    
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Message.timestamp, ascending: true)],
        animation: .default)
    
    private var messages: FetchedResults<Message>
    
    
    
    @StateObject  var networkMonitor = NetworkMonitor()
    
    @State var   showingAlert = false
    
    @State var newMessage: String = ""
    @State var newMessageTemp: String = ""
    @State var isLoading: Bool = false
    
    // Set your model & API key here.
    // You can get it from https://ai.google.dev/ 
    private let model = GenerativeModel(name: "gemini-pro", apiKey: "YOUR_API_KEY")
    
    var body: some View {
        
        NavigationView{
            VStack{
                if networkMonitor.isConnected {
                    VStack {
                        ScrollViewReader { proxy in
                            ScrollView {
                                LazyVStack {
                                    
                                    if messages.count == 0{
                                        
                                        Image("ai")
                                            .resizable()
                                            .background(.black)
                                            .clipShape(Circle())
                                            .overlay {
                                                Circle().stroke(.black, lineWidth: 2)
                                            }
                                            .frame(width: 150, height: 150, alignment: .center)
                                            .padding(.top, 100)
                                        
                                        Text("Hi, how can I help you today?")
                                            .font(.title)
                                            .padding()
                                        
                                    } else {
                                        ForEach(messages, id: \.self) { message in
                                            MessageView(currentMessage: message)
                                                .id(message)
                                        }
                                    }
                                }
                                
                                
                                .onReceive(Just(messages)) { _ in
                                    withAnimation {
                                        proxy.scrollTo(messages.last, anchor: .bottom)
                                    }
                                    
                                }.onAppear {
                                    withAnimation {
                                        proxy.scrollTo(messages.last, anchor: .bottom)
                                    }
                                }
                            }
                            
                            .onTapGesture {
                                hideKeyboard()
                            }
                            
                            // send new message
                            HStack {
                                TextField("Ask me anything", text: isLoading ? $newMessageTemp : $newMessage)
                                    .textFieldStyle(.roundedBorder)
                                
                                if isLoading{
                                    ProgressView()
                                        .padding(.leading, 3.0)
                                }
                                else{
                                    Button(action: {
                                        sendMessage()
                                        isLoading = true
                                        
                                    }, label: {
                                        Image(systemName: "paperplane")
                                    }).disabled(newMessage.isEmpty)
                                }
                                
                            }
                            .padding()
                        }
                    }
                    
                } else {
                    NetworkUnavailableView()
                }
                
                
            }
            .navigationTitle("Gemini AI - SwiftUI ")
            .navigationBarTitleDisplayMode(.inline)
            
            .toolbar {
                ToolbarItem (placement: .navigationBarTrailing){
                    
                    Button(action: {
                        showingAlert = true
                    }, label: {
                        Label("Clear Chat", systemImage: "trash")
                    })
                    .alert("Are you sure you want to clear chat history?", isPresented: $showingAlert) {
                        Button("Cancel", role: .cancel) { }
                        Button("Delete", role: .destructive) {
                            let fetchRequest = Message.fetchRequest()
                            let items = try? viewContext.fetch(fetchRequest)
                            for item in items ?? [] {
                                viewContext.delete(item)
                            }
                            try? viewContext.save()
                        }
                    }
                    
                }
                
            }
            
        }
        
        
    }
    
    func sendMessage() {
        
        if !newMessage.isEmpty{
            
            addMessage(chatText: newMessage, currentUser: true)
            
            
            Task {
                
                do{
                    let prompt = newMessage
                    let response = try await model.generateContent(prompt)
                    if let text = response.text {
                        
                        addMessage(chatText: text, currentUser: false)
                        
                        newMessage = ""
                        isLoading = false
                    }
                } catch {
                    
                    addMessage(chatText: "Sorry, didn't get that. Can you please try again?", currentUser: false)
                    
                    newMessage = ""
                    isLoading = false
                }
            }
        }
    }
    
    
    func addMessage(chatText: String, currentUser: Bool){
        
        let newContent = Message(context: viewContext)
        newContent.content = chatText
        newContent.isCurrentUser = currentUser
        newContent.timestamp = Date()
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            print("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        
    }
}

extension View {
    func hideKeyboard() {
        let resign = #selector(UIResponder.resignFirstResponder)
        UIApplication.shared.sendAction(resign, to: nil, from: nil, for: nil)
    }
}

#Preview {
    ChatView()
}
