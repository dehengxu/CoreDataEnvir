    #!/usr/bin/env bash
    #不检查 cocoapods 数据库，直接更新内部模块

    mode=$1

    if [ -z $mode ]
    then
      mode="update --no-repo-update"
    elif [ $mode == "u" ]
    then
      mode="update --no-repo-update"
    elif [ $mode == "i" ]
    then
      mode="install --no-repo-update"
    elif [ $mode == "c" ]
    then
      rm -rf *.xcworkspace
      rm -rf Pods/
      rm Podfile.lock
      echo "Clear pod generated files."
      exit 0
    else
      echo "usage:"
      echo "./podupdate.sh i [\"for installing new libs\"]"
      echo "./podupdate.sh u [\"for updating exist libs\"]"
      exit 0
    fi

    echo $mode

    pod $mode
