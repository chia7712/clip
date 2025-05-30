import os
import shutil
import argparse

def copy_files_with_substring(search_strings, source_folder):
    """
    將指定資料夾中檔名包含輸入字串的檔案複製到 'commit_stats' 目錄。

    Args:
        search_strings (list): 包含用於搜尋檔名的字串列表。
        source_folder (str): 來源資料夾的路徑。
    """

    # 定義目標資料夾路徑
    destination_folder = os.path.join(source_folder, "commit_stats")

    # 如果目標資料夾不存在，則建立它
    if not os.path.exists(destination_folder):
        os.makedirs(destination_folder)
        print(f"已建立目標資料夾: {destination_folder}")
    else:
        print(f"目標資料夾已存在: {destination_folder}")

    found_files_count = 0
    # 遍歷來源資料夾中的所有檔案
    for filename in os.listdir(source_folder):
        file_path = os.path.join(source_folder, filename)

        # 檢查是否為檔案，並且檔名是否包含任何一個搜尋字串
        if os.path.isfile(file_path) and any(s in filename for s in search_strings):
            try:
                shutil.copy(file_path, destination_folder)
                print(f"已複製檔案: {filename} 到 {destination_folder}")
                found_files_count += 1
            except Exception as e:
                print(f"複製檔案 {filename} 時發生錯誤: {e}")

    if found_files_count == 0:
        print("沒有找到任何符合條件的檔案。")
    else:
        print(f"總共複製了 {found_files_count} 個檔案。")

# --- 命令列參數解析 ---
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="根據檔名包含的字串，將檔案複製到 'commit_stats' 目錄。")
    parser.add_argument(
        "-s", "--strings",
        type=str,
        required=True,
        help="逗號分隔的搜尋字串 (例如: .log,.txt,report)"
    )
    parser.add_argument(
        "-f", "--folder",
        type=str,
        required=True,
        help="來源資料夾的路徑 (例如: /path/to/your/folder)"
    )

    args = parser.parse_args()

    # 將逗號分隔的字串轉換為列表
    search_strings_list = [s.strip() for s in args.strings.split(',')]

    copy_files_with_substring(search_strings_list, args.folder)