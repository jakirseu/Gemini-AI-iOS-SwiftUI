import SwiftUI

struct MessageView : View {
    var currentMessage: Message
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            if !currentMessage.isCurrentUser {
                
                Image("ai")
                    .resizable()
                    .background(.black)
                    .clipShape(Circle())
                    .overlay {
                        Circle().stroke(.black, lineWidth: 2)
                    }
                    .frame(width: 40, height: 40, alignment: .center)
                
            } else {
                Spacer()
            }
            MessageCell(contentMessage: currentMessage.content ?? "",
                        isCurrentUser: currentMessage.isCurrentUser)
            .contextMenu {
                Button(action: {
                    UIPasteboard.general.string = currentMessage.content
                }) {
                    Text("Copy to clipboard")
                    Image(systemName: "doc.on.doc")
                }
             }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }
}


 
