import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import os
import logging

# 配置日誌
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

def merge_and_plot_commit_stats(input_dir="commit_stats", output_filename="all_users_commit_trends.jpg"):
    """
    讀取指定目錄下的所有 CSV 檔案，合併提交統計數據，並繪製成折線圖。
    圖表會儲存為 JPG 檔案，但不會在執行後顯示視窗。

    Args:
        input_dir (str): 存放 CSV 檔案的目錄。
        output_filename (str): 輸出圖片的檔案名稱 (JPG 格式)。
    """
    
    logging.info(f"開始處理 CSV 檔案，輸入目錄：{input_dir}")
    
    all_commits_data = []
    
    if not os.path.exists(input_dir):
        logging.error(f"錯誤：輸入目錄 '{input_dir}' 不存在。請確認已執行先前的程式並生成 CSV 檔案。")
        print(f"錯誤：輸入目錄 '{input_dir}' 不存在。請確認已執行先前的程式並生成 CSV 檔案。")
        return

    csv_files = [f for f in os.listdir(input_dir) if f.endswith('_commit_stats.csv')]
    
    if not csv_files:
        logging.warning(f"在目錄 '{input_dir}' 中沒有找到任何 'commit_stats.csv' 檔案。")
        print(f"在目錄 '{input_dir}' 中沒有找到任何 'commit_stats.csv' 檔案。")
        return

    for file_name in csv_files:
        file_path = os.path.join(input_dir, file_name)
        try:
            # 從檔案名稱中提取使用者名稱 (例如: "john_doe_commit_stats.csv" -> "john_doe")
            author_name = file_name.replace('_commit_stats.csv', '')
            
            df = pd.read_csv(file_path)
            df['Author'] = author_name
            all_commits_data.append(df)
            logging.info(f"已讀取檔案：{file_name}，作者：{author_name}")
        except Exception as e:
            logging.error(f"讀取檔案 '{file_name}' 時發生錯誤：{e}")
            continue

    if not all_commits_data:
        logging.error("沒有成功讀取任何提交數據，無法生成圖表。")
        print("沒有成功讀取任何提交數據，無法生成圖表。")
        return

    # 合併所有數據
    combined_df = pd.concat(all_commits_data, ignore_index=True)
    
    # 將 'Date' 欄位轉換為日期時間格式，方便繪圖
    combined_df['Date'] = pd.to_datetime(combined_df['Date'])
    
    # 確保數據按日期和作者排序
    combined_df = combined_df.sort_values(by=['Date', 'Author'])

    logging.info("數據合併完成，準備繪製折線圖。")

    # 繪製折線圖
    plt.figure(figsize=(15, 8)) # 設定圖形大小
    sns.lineplot(data=combined_df, x='Date', y='CommitCount', hue='Author', marker='o') # 使用 hue 區分不同作者
    
    plt.title('Daily Commit Trends by Author', fontsize=18)
    plt.xlabel('Date', fontsize=14)
    plt.ylabel('Number of Commits', fontsize=14)
    plt.xticks(rotation=45) # 旋轉 x 軸標籤以避免重疊
    plt.grid(True, linestyle='--', alpha=0.7) # 增加格線
    plt.legend(title='Author', bbox_to_anchor=(1.05, 1), loc='upper left') # 將圖例放在圖形外側
    plt.tight_layout() # 自動調整佈局，避免標籤重疊

    # 儲存圖表
    try:
        # 移除 'quality=90' 參數，因為您的 Matplotlib 版本不支持它
        plt.savefig(output_filename, dpi=300) 
        logging.info(f"折線圖已成功儲存為：{output_filename}")
        print(f"\n折線圖已成功儲存為：{output_filename}")
    except Exception as e:
        logging.error(f"儲存圖片 '{output_filename}' 時發生錯誤：{e}")
        print(f"儲存圖片 '{output_filename}' 時發生錯誤：{e}")

    # 移除 plt.show()，讓圖表不會顯示在視窗中
    # plt.show() 

if __name__ == "__main__":
    logging.info("繪圖程式啟動。")
    merge_and_plot_commit_stats()
    logging.info("繪圖程式執行完畢。")
