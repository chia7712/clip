import csv
from datetime import datetime
from github import Github
import os
import logging

# 配置日誌
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

def get_github_commits_by_user_and_date(repo_owner, repo_name, access_token=None):
    """
    獲取 GitHub 倉庫的提交記錄，並按使用者和日期統計。

    Args:
        repo_owner (str): 倉庫擁有者的使用者名稱。
        repo_name (str): 倉庫名稱。
        access_token (str, optional): 您的 GitHub 個人訪問令牌。
                                      如果提供，可以增加 API 請求限制。

    Returns:
        None
    """

    logging.info(f"開始處理倉庫：{repo_owner}/{repo_name}")

    if access_token:
        g = Github(access_token)
        logging.info("使用提供的個人訪問令牌連接 GitHub。")
    else:
        g = Github()
        logging.info("以匿名方式連接 GitHub (可能會受到 API 速率限制)。")

    try:
        logging.info(f"嘗試獲取倉庫：{repo_owner}/{repo_name}")
        repo = g.get_user(repo_owner).get_repo(repo_name)
        logging.info(f"成功獲取倉庫物件：{repo_owner}/{repo_name}")
    except Exception as e:
        logging.error(f"錯誤：無法找到倉庫 {repo_owner}/{repo_name}。請檢查倉庫名稱和擁有者是否正確。錯誤訊息：{e}")
        return

    logging.info(f"正在從倉庫 {repo_owner}/{repo_name} 獲取所有提交記錄...")

    commits_by_user_date = {}
    commit_count = 0

    try:
        for commit in repo.get_commits():
            commit_count += 1
            if commit_count % 100 == 0: # 每處理100個提交就輸出一次日誌
                logging.info(f"已處理 {commit_count} 個提交...")

            # 確保提交者資訊存在
            author_name = "unknown"
            if commit.author:
                author_name = commit.author.login
            elif commit.commit.author:
                author_name = commit.commit.author.name
            
            commit_date = commit.commit.author.date.strftime('%Y-%m-%d')

            if author_name not in commits_by_user_date:
                commits_by_user_date[author_name] = {}
                logging.debug(f"新發現提交者：{author_name}") # 使用 debug 等級，除非詳細偵錯才顯示
            if commit_date not in commits_by_user_date[author_name]:
                commits_by_user_date[author_name][commit_date] = 0
                logging.debug(f"新發現 {author_name} 在 {commit_date} 的提交記錄。") # 使用 debug 等級
            
            commits_by_user_date[author_name][commit_date] += 1
        
        logging.info(f"所有提交記錄獲取完畢。總共處理了 {commit_count} 個提交。")

    except Exception as e:
        logging.error(f"在獲取提交記錄時發生錯誤：{e}")
        logging.warning("您可能遇到了 API 請求限制，或者您的令牌權限不足。請稍後重試，或檢查您的個人訪問令牌。")
        return

    output_dir = "commit_stats"
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
        logging.info(f"已建立輸出資料夾：{output_dir}")
    else:
        logging.info(f"輸出資料夾 '{output_dir}' 已存在。")

    logging.info("開始生成每個使用者的 CSV 檔案...")
    for author, dates in commits_by_user_date.items():
        filename = os.path.join(output_dir, f"{author}_commit_stats.csv")
        try:
            with open(filename, 'w', newline='', encoding='utf-8') as csvfile:
                fieldnames = ['Date', 'CommitCount']
                writer = csv.DictWriter(csvfile, fieldnames=fieldnames)

                writer.writeheader()
                sorted_dates = sorted(dates.keys())
                for date in sorted_dates:
                    writer.writerow({'Date': date, 'CommitCount': dates[date]})
            logging.info(f"成功儲存 {author} 的提交統計到 {filename}")
        except Exception as e:
            logging.error(f"儲存 {filename} 時發生錯誤：{e}")
            
    logging.info("所有 CSV 檔案生成完畢。")
    logging.info("程式執行完畢。請檢查 'commit_stats' 資料夾。")

if __name__ == "__main__":
    logging.info("程式啟動。")

    repo_owner = input("請輸入 GitHub 倉庫擁有者 (例如: octocat): ")
    repo_name = input("請輸入 GitHub 倉庫名稱 (例如: Spoon-Knife): ")
    
    access_token = input("請輸入您的 GitHub 個人訪問令牌 (可選，留空則使用匿名訪問): ")
    if not access_token:
        access_token = None

    get_github_commits_by_user_and_date(repo_owner, repo_name, access_token)
    logging.info("程式主流程結束。")
