if status is-interactive
    # Commands to run in interactive sessions can go here
    
    set -x PAGER less
    set -x EDITOR nvim
    set -x VISUAL nvim
    
    set -l fish_reserved_vars PWD SHLVL _

    if test -f ~/.profile
        
        for env_line in (bash -lc 'source ~/.profile > /dev/null 2>&1; printenv')
            
            # 1. Chia chuỗi tại vị trí dấu '=' (max-split 1)
            set -l parts (echo $env_line | string split -m 1 '=')
            
            # Kiểm tra xem có đủ 2 phần tử (KEY và VALUE) không
            if test (count $parts) -ge 2
                
                set -l key $parts[1]
                set -l value $parts[2]
                
                # 2. KIỂM TRA LỌC: Bỏ qua các biến chỉ đọc đã biết
                if contains $key $fish_reserved_vars
                    continue # Chuyển sang vòng lặp tiếp theo
                end
                
                # Thiết lập biến môi trường toàn cục (global -gx) trong Fish
                if test -n "$key"
                    set -gx $key $value
                end
            end
            
        end
    end
end
