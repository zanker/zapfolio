Capistrano::Configuration.instance(:must_exist).load do
  before "deploy" do
    logger.info "Pushing git repo for branch #{branch}"
    run_locally(source.scm("push", "origin", branch))

    next if ENV["RSPEC"] == "0"

    logger.info "Running tests"

    results = system("rspec ./")
    unless results
      raise Capistrano::Error.new("Test failure, deploy aborted")
    end
  end

  before "bundle:install" do
    logger.info "Loading submodules"
    run "cd #{latest_release} && git submodule init && git submodule update && chown -R deploy:deploy #{latest_release}/shared"
  end

  after "deploy:update_code" do
    unless ENV["RECOMPILE"] == "1"
      commits = run_locally(source.scm("log", "--name-only", "#{previous_revision}..#{latest_revision}"))
      unless commits =~ /app\/assets/i
        logger.info "No asset changes, copying previous data over instead"
        run "cp -r #{previous_release}/public/assets #{latest_release}/public/assets", :roles => [:app]
        next
      end
    end

    run "cd #{latest_release} && #{rake} RAILS_ENV=#{rails_env} RAILS_GROUPS=assets assets:precompile", :roles => [:app]
  end

  after "deploy:update_code" do
    run "mkdir -p #{shared_path}/tmp/dragonfly && ln -nfs #{shared_path}/tmp/dragonfly #{release_path}/tmp/dragonfly"
  end

  after "deploy" do
    run "curl -s https://www.zapfol.io > null"
  end
end