//
//  AccountsManagementView.swift
//  NetNewsWire-iOS
//
//  Created by Stuart Breckenridge on 13/11/2022.
//  Copyright © 2022 Ranchero Software. All rights reserved.
//

import SwiftUI
import Account
import Combine

public final class AccountManagementViewModel: ObservableObject {
	
	@Published var sortedActiveAccounts = [Account]()
	@Published var sortedInactiveAccounts = [Account]()
	@Published var accountsForDeletion = [Account]()
	@Published var showAccountDeletionAlert: Bool = false
	@Published var showAddAccountSheet: Bool = false
	public var accountToDelete: Account? = nil
	
	init() {
		refreshAccounts()
		
		NotificationCenter.default.addObserver(forName: .AccountStateDidChange, object: nil, queue: .main) { [weak self] _ in
			self?.refreshAccounts()
		}
		
		NotificationCenter.default.addObserver(forName: .UserDidAddAccount, object: nil, queue: .main) { [weak self] _ in
			self?.refreshAccounts()
		}
		
		NotificationCenter.default.addObserver(forName: .UserDidDeleteAccount, object: nil, queue: .main) { [weak self] _ in
			self?.refreshAccounts()
		}
		
		NotificationCenter.default.addObserver(forName: .DisplayNameDidChange, object: nil, queue: .main) { [weak self] _ in
			self?.refreshAccounts()
		}
	}
	
	func temporarilyDeleteAccount(_ account: Account) {
		if account.isActive {
			sortedActiveAccounts.removeAll(where: { $0.accountID == account.accountID })
		} else {
			sortedInactiveAccounts.removeAll(where: { $0.accountID == account.accountID })
		}
		accountToDelete = account
		showAccountDeletionAlert = true
	}
	
	func restoreAccount(_ account: Account) {
		accountToDelete = nil
		self.refreshAccounts()
	}
	
	private func refreshAccounts() {
		sortedActiveAccounts = AccountManager.shared.sortedActiveAccounts
		sortedInactiveAccounts = AccountManager.shared.sortedAccounts.filter({ $0.isActive == false })
	}
		
}


struct AccountsManagementView: View {
    
	@StateObject private var viewModel = AccountManagementViewModel()
	
	var body: some View {
		List {
			Section(header: Text("Active Accounts", comment: "Active accounts section header")) {
				ForEach(viewModel.sortedActiveAccounts, id: \.self) { account in
					accountRow(account)
				}
			}
			
			Section(header: Text("Inactive Accounts", comment: "Inactive accounts section header")) {
				ForEach(viewModel.sortedInactiveAccounts, id: \.self) { account in
					accountRow(account)
				}
			}
		}
		.navigationTitle(Text("Manage Accounts", comment: "Navigation title: Manage Accounts"))
		.toolbar {
			ToolbarItem(placement: .navigationBarTrailing) {
				Button {
					viewModel.showAddAccountSheet = true
				} label: {
					Image(systemName: "plus")
				}
			}
		}
		.sheet(isPresented: $viewModel.showAddAccountSheet) {
			AddAccountListView()
		}
		.alert(Text("Are you sure you want to remove “\(viewModel.accountToDelete?.nameForDisplay ?? "")”?", comment: "Alert title: confirm account removal"),
			   isPresented: $viewModel.showAccountDeletionAlert) {
			Button(role: .destructive) {
				AccountManager.shared.deleteAccount(viewModel.accountToDelete!)
			} label: {
				Text("Remove Account", comment: "Button title")
			}
			
			Button(role: .cancel) {
				viewModel.restoreAccount(viewModel.accountToDelete!)
			} label: {
				Text("Cancel", comment: "Button title")
			}
		} message: {
			switch viewModel.accountToDelete {
			case .none:
			    Text("")
			case .some(let account):
				switch account.type {
				case .feedly:
					Text("Are you sure you want to remove this account? NetNewsWire will no longer be able to access articles and feeds unless the account is added again.", comment: "Alert message: remove Feedly account confirmation")
				default:
					Text("Are you sure you want to remove this account? This cannot be undone.", comment: "Alert message: remove account confirmation")
				}
			}
		}
    }
	
	func accountRow(_ account: Account) -> some View {
		NavigationLink {
			AccountInspectorView(account: account)
		} label: {
			Image(uiImage: account.smallIcon!.image)
				.resizable()
				.aspectRatio(contentMode: .fit)
				.frame(width: 25, height: 25)
			Text(account.nameForDisplay)
		}
		.swipeActions(edge: .trailing, allowsFullSwipe: false) {
			if account != AccountManager.shared.defaultAccount {
				Button(role: .destructive) {
					viewModel.temporarilyDeleteAccount(account)
				} label: {
					Label {
						Text("Remove Account", comment: "Button title")
					} icon: {
						Image(systemName: "trash")
					}
				}
			}
			Button {
				withAnimation {
					account.isActive.toggle()
				}
			} label: {
				if account.isActive {
					Image(systemName: "minus.circle")
				} else {
					Image(systemName: "togglepower")
				}
			}.tint(account.isActive ? .yellow : Color(uiColor: AppAssets.primaryAccentColor))
		}
	}
}

struct AddAccountView_Previews: PreviewProvider {
    static var previews: some View {
        AccountsManagementView()
    }
}
