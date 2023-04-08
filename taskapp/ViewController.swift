//
//  ViewController.swift
//  taskapp
//
//  Created by yamadakota on 2023/03/31.
//

import UIKit
import RealmSwift
import UserNotifications

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var categorySearchBar: UISearchBar!
    
    
    // Realmインスタンスを取得する
    let realm = try! Realm()
    
    // Taskクラスの配列を定義
    var data: Results<Task>!
    var filteredData: Results<Task>!
    
    var isSearching = false
    
    // DB内のタスクが格納されるリスト
    // 日付の近い順でソート，昇順
    // 以降内容をアップデートするとリスト内は自動的に更新される
    var taskArray = try! Realm().objects(Task.self).sorted(byKeyPath: "date", ascending: true)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        // データを表示していない部分に罫線を表示する
        tableView.fillerRowHeight = UITableView.automaticDimension
        
        tableView.delegate = self
        tableView.dataSource = self
        categorySearchBar.delegate = self
        
        // task配列を初期化
        data = realm.objects(Task.self)
        filteredData = data
        
        // 何も入力されていなくてもReturnキーを押せるようにする
        categorySearchBar.enablesReturnKeyAutomatically = false

    }
    
    // タスク入力画面に遷移する際にデータを渡す
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let inputViewController:InputViewController = segue.destination as! InputViewController

        if segue.identifier == "cellSegue" {
            let indexPath = self.tableView.indexPathForSelectedRow
            inputViewController.task = filteredData[indexPath!.row]
        } else {
            inputViewController.task = Task()
        }
    }
    
    // タスク入力画面から戻ってきたときにTableViewの情報を更新する
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    // UITableViewDataSourceプロトコルのメソッドで，データの数(=セルの数)を返す
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isSearching {
            return filteredData.count  // 検索時は当てはまるものの数だけ返す
        } else {
            return data.count  // それ以外は全て返す
        }
    }
    
    // UITableViewDataSourceプロトコルのメソッドで，セルの内容を返す
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // 再利用可能なcellを得る
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        //Cellに値を設定する．検索時はfilteredTask，それ以外はtaskを返す
        if isSearching {
            cell.textLabel?.text = filteredData[indexPath.row].title
        } else {
            cell.textLabel?.text = data[indexPath.row].title
        }
        
        let task = taskArray[indexPath.row]
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        let dateString:String = formatter.string(from: task.date)
        cell.detailTextLabel?.text = dateString
        
        return cell
    }
    
    // UITableViewDelegateプロトコルのメソッドで，セルをタップしたときにタスク入力画面に遷移させる
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "cellSegue", sender: nil)
    }
    
    // UITableViewDelegateプロトコルのメソッドで，セルが削除可能なことを伝える
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    // UITableViewDelegateプロトコルのメソッドで，Deleteボタンが押されたときにローカル通知をキャンセルし，データベースからタスクを削除する
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            // 削除するタスクを取得する
            let task = self.taskArray[indexPath.row]
            
            // ローカル通知をキャンセルする
            let center = UNUserNotificationCenter.current()
            center.removePendingNotificationRequests(withIdentifiers: [String(task.id.stringValue)])
            
            // データベースから削除する
            try! realm.write {
                self.realm.delete(self.taskArray[indexPath.row])
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
            
            // 未通知のローカル通知一覧をログ出力
            center.getPendingNotificationRequests { (requests: [UNNotificationRequest]) in
                for request in requests {
                    print("/-------------")
                    print(request)
                    print("-------------/")
                }
            }
        }
    }
    
    // 検索を実行し，当てはまるものだけを返す
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // 何も入力しないときは全てのセルをそのまま返す
        if searchText == "" {
            isSearching = false
            tableView.reloadData()
        // カテゴリに検索した文字が含まれているときfilteredTaskに追加
        } else {
            isSearching = true
            filteredData = data.filter("category CONTAINS[cd] %@", searchText)
            tableView.reloadData()
        }
    }
}

