//
//  FeedViewController.swift
//  lab-insta-parse
//

import UIKit
import ParseSwift

// Single source of truth for the session gate key
private enum SessionGate {
    static let key = "hasPostedThisSession"
}

final class FeedViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!

    // Data source
    private var posts: [Post] = [] {
        didSet { tableView.reloadData() }
    }

    // A centered, multi-line message that sits behind the table’s cells.
    private lazy var emptyLabel: UILabel = {
        let l = UILabel()
        l.text = "You need to upload a photo before you can see your friends' feed!"
        l.textAlignment = .center
        l.numberOfLines = 0
        l.textColor = .secondaryLabel
        return l
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        tableView.allowsSelection = false

        tableView.backgroundView = emptyLabel
        tableView.separatorStyle = .none

        // Start in "blocked" state until the gate passes
        showEmptyMessage()
        posts = []

        // Refresh after a successful post (from PostViewController)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleDidCreatePost),
                                               name: .didCreatePost,
                                               object: nil)

        // Reset the session gate when a new login happens
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleLogin),
                                               name: Notification.Name("login"),
                                               object: nil)

        // Also clear UI on logout
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleLogout),
                                               name: Notification.Name("logout"),
                                               object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        enforcePostGate()
    }

    // MARK: - Notifications

    @objc private func handleDidCreatePost() {
        // Mark session as unblocked and refresh feed
        UserDefaults.standard.set(true, forKey: SessionGate.key)
        enforcePostGate()
    }

    @objc private func handleLogin() {
        // New session after login -> require a fresh post
        UserDefaults.standard.set(false, forKey: SessionGate.key)
        showEmptyMessage()
        posts = []
    }

    @objc private func handleLogout() {
        UserDefaults.standard.set(false, forKey: SessionGate.key)
        showEmptyMessage()
        posts = []
    }

    // MARK: - Gate: must post during this session

    private func enforcePostGate() {
        // If not logged in, keep blocked UI
        guard let currentUser = User.current else {
            showEmptyMessage()
            posts = []
            return
        }

        // 1) Session check: have they posted SINCE this session started?
        let hasPostedThisSession = UserDefaults.standard.bool(forKey: SessionGate.key)
        if !hasPostedThisSession {
            // Block images/feed for this session
            showEmptyMessage()
            posts = []
            return
        }

        // 2) (Safety) Verify they actually have at least one post on server.
        // Using find(limit: 1) avoids CLP issues with count.
        do {
            let existsQuery = try Post.query("user" == currentUser).limit(1)
            existsQuery.find { [weak self] result in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    switch result {
                    case .success(let items):
                        if items.isEmpty {
                            // Shouldn't happen if session flag is true, but be safe.
                            self.showEmptyMessage()
                            self.posts = []
                        } else {
                            self.hideEmptyMessage()
                            self.queryPosts()
                        }
                    case .failure(let error):
                        self.showAlert(description: error.localizedDescription)
                    }
                }
            }
        } catch {
            showAlert(description: error.localizedDescription)
        }
    }

    // MARK: - Fetch posts (only called when gate passes)

    private func queryPosts() {
        let query = Post.query()
            .include("user")
            .order([.descending("createdAt")])

        query.find { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let posts):
                self.posts = posts
            case .failure(let error):
                self.showAlert(description: error.localizedDescription)
            }
        }
    }

    private func showEmptyMessage() {
        emptyLabel.isHidden = false
        tableView.separatorStyle = .none
    }

    private func hideEmptyMessage() {
        emptyLabel.isHidden = true
        tableView.separatorStyle = .singleLine
    }

    // MARK: - Logout button

    @IBAction func onLogOutTapped(_ sender: Any) {
        showConfirmLogoutAlert()
    }

    private func showConfirmLogoutAlert() {
        let alertController = UIAlertController(title: "Log out of your account?", message: nil, preferredStyle: .alert)
        let logOutAction = UIAlertAction(title: "Log out", style: .destructive) { _ in
            NotificationCenter.default.post(name: Notification.Name("logout"), object: nil)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(logOutAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true)
    }

    // MARK: - Alerts

    private func showAlert(description: String? = nil) {
        let alertController = UIAlertController(
            title: "Oops...",
            message: description ?? "Please try again...",
            preferredStyle: .alert
        )
        let action = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(action)
        present(alertController, animated: true)
    }
}

// MARK: - Table

extension FeedViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        posts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell",
                                                       for: indexPath) as? PostCell else {
            return UITableViewCell()
        }
        cell.configure(with: posts[indexPath.row])
        return cell
    }
}

extension FeedViewController: UITableViewDelegate { }
