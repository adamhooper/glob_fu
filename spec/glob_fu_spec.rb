require File.dirname(__FILE__) + '/spec_helper'

describe(GlobFu) do
  after(:each) do
    wipe_fs
  end

  describe('#find') do
    it('should find /full/path/to/x') do
      fs('x')
      f("#{prefix}/x").should == ["#{prefix}/x"]
    end

    it('should order x before y') do
      Dir.should_receive(:[]).and_return(["#{prefix}/y", "#{prefix}/x"])
      f("#{prefix}/*").should == ["#{prefix}/x", "#{prefix}/y"]
    end

    it('should order first-glob before second-glob') do
      fs('y', 'x')
      f('y', 'x', :root => prefix).should == ["#{prefix}/y", "#{prefix}/x"]
    end

    it('should find /full/path/to/*') do
      fs('x')
      f("#{prefix}/*").should == ["#{prefix}/x"]
    end

    it('should iterate over results') do
      fs('x')
      yielded = nil
      f("#{prefix}/x") { |f| yielded = f }
      yielded.should == "#{prefix}/x"
    end

    it('should glob "**"') do
      fs('x/y')
      f("#{prefix}/**/y").should == ["#{prefix}/x/y"]
    end

    it('should use :root') do
      fs('x')
      f('x', :root => prefix).should == ["#{prefix}/x"]
    end

    it('should allow two arguments') do
      fs('x', 'y')
      f('x', 'y', :root => prefix).should == ["#{prefix}/x", "#{prefix}/y"]
    end

    it('should allow Array argument') do
      fs('x', 'y')
      f(['x', 'y'], :root => prefix).should == ["#{prefix}/x", "#{prefix}/y"]
    end

    it('should remove duplicates') do
      fs('x')
      f('x', 'x', :root => prefix).should == ["#{prefix}/x"]
    end

    it('should use :suffix') do
      fs('x.txt')
      f('x', :root => prefix, :suffix => 'txt').should == ["#{prefix}/x.txt"]
    end

    it('should ignore double-suffixed when using :suffix') do
      fs('x.X.txt')
      f('*', :root => prefix, :suffix => 'txt').should == []
    end

    it('should use :optional_suffix to find files') do
      fs('x.txt.gz')
      f('x', :root => prefix, :suffix => 'txt', :optional_suffix => 'gz').should == ["#{prefix}/x.txt.gz"]
    end

    it('should prefer :optional_suffix over other') do
      fs('x.txt', 'x.txt.gz')
      f('x', :root => prefix, :suffix => 'txt', :optional_suffix => 'gz').should == ["#{prefix}/x.txt.gz"]
    end

    it('should fall back to non-:optional_suffix if it is not there') do
      fs('x.txt')
      f('x', :root => prefix, :suffix => 'txt', :optional_suffix => 'gz').should == ["#{prefix}/x.txt"]
    end

    it('should allow :extra_suffix') do
      fs('x.X.txt')
      f('x', :root => prefix, :suffix => 'txt', :extra_suffix => 'X').should == ["#{prefix}/x.X.txt"]
    end

    it('should ignore un-:extra_suffixed') do
      fs('x.txt')
      f('x', :root => prefix, :suffix => 'txt', :extra_suffix => 'X').should == []
    end

    it('should need a dot before :extra_suffix') do
      fs('xX.txt', 'xX.X.txt')
      f('xX', :root => prefix, :suffix => 'txt', :extra_suffix => 'X').should == [ "#{prefix}/xX.X.txt" ]
    end

    it('should allow :extra_suffix and :optional_suffix in combination') do
      fs('x.X.txt.gz')
      f('x', :root => prefix, :suffix => 'txt', :extra_suffix => 'X', :optional_suffix => 'gz').should == ["#{prefix}/x.X.txt.gz"]
    end
  end

  private

  def f(*args, &block)
    GlobFu.find(*args, &block)
  end

  def prefix
    @prefix ||= File.dirname(__FILE__) + '/deleteme'
  end

  def fs(*files)
    wipe_fs
    FileUtils.mkdir(prefix)

    files.each do |file|
      path = File.join(prefix, file)
      dir = File.dirname(path)
      unless File.exist?(dir)
        FileUtils.mkdir_p(dir)
      end
      File.open(path, 'w') { |f| f.write("stub\n") }
    end
  end

  def wipe_fs
    if File.exist?(prefix)
      FileUtils.rm_r(prefix)
    end
  end
end
