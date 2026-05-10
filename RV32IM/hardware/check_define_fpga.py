import os

def check_define_fpga():
    # 현재 디렉토리 경로 가져오기
    current_directory = os.getcwd()
    print(f"현재 디렉토리: {current_directory}")
    print("")

    # 디렉토리와 결과를 저장할 리스트
    results = []

    # 모든 하위 디렉토리를 탐색하며 sim_define.v 파일을 확인
    directories = []
    for root, dirs, files in os.walk(current_directory):
        directories.append(root)
    
    # 디렉토리 정렬
    directories.sort()

    for root in directories:
        # 각 디렉토리에서 sim_define.v 파일 존재 여부 확인
        if "sim_define.v" in os.listdir(root):
            file_path = os.path.join(root, "sim_define.v")
            with open(file_path, "r") as file:
                lines = file.readlines()
                # 주석 처리가 없는 `define FPGA를 찾기
                define_fpga_found = False
                for line in lines:
                    # 라인의 앞뒤 공백 제거 후 주석 여부 확인
                    stripped_line = line.strip()
                    # `define FPGA가 있으면서도, `//` 주석처리가 없는지 확인
                    if "`define FPGA" in stripped_line and not stripped_line.startswith("//"):
                        define_fpga_found = True
                        break

                # 상대 경로 계산
                relative_path = os.path.relpath(root, current_directory)
                
                # 결과 출력 및 리스트 저장
                if define_fpga_found:
                    print(f"디렉토리: {relative_path}")
                    print(f"파일: sim_define.v")
                    print("`define FPGA 선언이 확인되었습니다.\n")
                    results.append((relative_path, "O"))
                else:
                    print(f"디렉토리: {relative_path}")
                    print(f"파일: sim_define.v")
                    print("`define FPGA 선언이 **존재하지 않습니다.**\n")
                    results.append((relative_path, "X"))

    # Summary 출력
    print("\n==== Summary ====")
    for dir_name, status in results:
        print(f"{dir_name} : {status}")

if __name__ == "__main__":
    check_define_fpga()

