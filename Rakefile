def gem_opt
  defined?(Gem) ? "-rubygems" : ""
end

# --------------------------------------------------
# Tests
# --------------------------------------------------
task(:default => "test:all")

namespace(:test) do

  desc "Run all tests"
  task(:all) do
    tests = FileList['test/**/test_*.rb'] - FileList['test/test_helper.rb']
    ruby %(#{gem_opt} -I.:lib -e"%w( #{tests.join(' ')} ).each {|file| require file }")
  end

  desc "Run all tests on multiple ruby versions (requires rvm)"
  task(:portability) do
    %w( 1.8.6  1.8.7  1.9.1  1.9.2 ).each do |version|
      system <<-BASH
        bash -c 'source ~/.rvm/scripts/rvm;
                 rvm #{version};
                 echo "--------- v#{version} ----------\n";
                 rake -s test:all'
      BASH
    end
  end
end
