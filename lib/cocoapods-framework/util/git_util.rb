module Pod
  module GitUtil
    def prepare_git_with_configs configs, work_dir
      index = 0
      configs.each do |config|
        name = config["name"]
        git_url = config["git_url"]
        git_branch = config["git_branch"]
        command = "git clone #{git_url} -b #{git_branch} #{work_dir}/#{name}"
        Cmmd.sh! command
      end
    end
  end
end