import SwiftUI

struct NetworkUnavailableView: View {
    var body: some View {

        
        Image(systemName: "wifi.exclamationmark")
            .font(.system(size: 200))
        
        Text("No Internet Connection")
            .font(.title)
    
            .foregroundColor(Color(.systemGray5))
        Text("Please check your connection and try again.")
    }
}

#Preview {
    NetworkUnavailableView()
}
