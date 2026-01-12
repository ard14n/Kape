import SwiftUI

struct TournamentInterstitialView: View {
    @Bindable var viewModel: TournamentViewModel
    
    var body: some View {
        ZStack {
            // Background
            Color.black.edgesIgnoringSafeArea(.all)
            
            // Neon Glow Effect
            Circle()
                .fill(Color.neonGreen.opacity(0.15))
                .frame(width: 300, height: 300)
                .blur(radius: 60)
            
            VStack(spacing: 40) {
                Spacer()
                
                // Handoff Icon (AC Requirement)
                Image(systemName: "iphone.gen3.radiowaves.left.down.right.up")
                    .font(.system(size: 60))
                    .foregroundColor(Color.neonGreen)
                    .shadow(color: Color.neonGreen.opacity(0.5), radius: 10)
                    .padding(.bottom, 20)
                
                // Header
                Text(viewModel.currentPlayer.name)
                    .font(.system(size: 80, weight: .heavy, design: .rounded)) // AC: 80pt+
                    .foregroundColor(Color.neonGreen)
                    .multilineTextAlignment(.center)
                    .shadow(color: Color.neonGreen.opacity(0.5), radius: 10)
                    .minimumScaleFactor(0.5) // Allow scaling down for long names
                
                Text("Raundi \(viewModel.tournamentState?.currentRound ?? 1) / \(viewModel.config.roundsPerPlayer)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                // Action Button
                Button(action: {
                    viewModel.startPlayerTurn()
                }) {
                    Text("GATI!")
                        .font(.title)
                        .fontWeight(.black)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(Color.neonGreen)
                        .cornerRadius(16)
                        .shadow(color: Color.neonGreen.opacity(0.5), radius: 15)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
            }
        }
    }
}



#Preview {
    let vm = TournamentViewModel()
    // Configure dummy state for preview
    vm.players = [Player(name: "Ana"), Player(name: "Beni")]
    vm.startTournament()
    return TournamentInterstitialView(viewModel: vm)
}
