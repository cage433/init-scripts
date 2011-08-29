dot_maker = "#{Dir.pwd}/.maker"
Dir.mkdir(dot_maker) unless File.exists?(dot_maker)

$project_packages = "#{dot_maker}/project_packages"
$external_packages = "#{dot_maker}/external_packages"
$java_packages = "#{dot_maker}/java_packages"
$scala_packages = "#{dot_maker}/scala_packages"


def find_packages(short_class, package_listing_files)
  if package_listing_files == String then
    find_packages(short_class, [package_listing_files])
  else
    packages = []
    regexp = /^#{short_class}\s+((\w|\.)+)/
    package_listing_files.each do |file|
      IO.readlines(file).each do |line|
        if line =~ regexp
          packages.unshift($1)
        end
      end
    end
    packages
  end
end
