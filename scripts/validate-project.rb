#!/usr/bin/env ruby
# Validates Xcode project integrity before building
# Checks: file references, SPM linkage, duplicates, required files

require "xcodeproj"

PROJECT_PATH = File.join(__dir__, "..", "QuanLyChiTieu.xcodeproj")
SOURCE_ROOT = File.join(__dir__, "..")

def colorize(text, code)
  "\e[#{code}m#{text}\e[0m"
end
def red(text); colorize(text, 31); end
def green(text); colorize(text, 32); end
def yellow(text); colorize(text, 33); end

errors = []
warnings = []

project = Xcodeproj::Project.open(PROJECT_PATH)
target = project.targets.first
auto_fixed = []

# ── 1. Check all source file references exist on disk ──
target.source_build_phase.files.each do |bf|
  next unless bf.file_ref&.real_path
  path = bf.file_ref.real_path.to_s
  unless File.exist?(path)
    errors << "Missing file: #{path}"
  end
end

target.resources_build_phase.files.each do |bf|
  next unless bf.file_ref&.real_path
  path = bf.file_ref.real_path.to_s
  unless File.exist?(path)
    errors << "Missing resource: #{path}"
  end
end

# ── 2. Check SPM packages are in frameworks build phase ──
unlinked = []
target.package_product_dependencies.each do |dep|
  linked = target.frameworks_build_phase.files.any? { |f| f.product_ref == dep }
  unless linked
    unlinked << dep
    warnings << "SPM product '#{dep.product_name}' not in frameworks build phase"
  end
end

# Auto-fix: add unlinked packages to frameworks
if unlinked.any?
  unlinked.each do |dep|
    build_file = project.new(Xcodeproj::Project::Object::PBXBuildFile)
    build_file.product_ref = dep
    target.frameworks_build_phase.files << build_file
    auto_fixed << "Linked '#{dep.product_name}' to frameworks build phase"
  end
  project.save
end

# ── 3. Check for duplicate file references in build phases ──
seen_sources = {}
target.source_build_phase.files.each do |bf|
  path = bf.file_ref&.path
  next unless path
  if seen_sources[path]
    warnings << "Duplicate source: #{path}"
  end
  seen_sources[path] = true
end

seen_resources = {}
target.resources_build_phase.files.each do |bf|
  path = bf.file_ref&.path
  next unless path
  if seen_resources[path]
    warnings << "Duplicate resource: #{path}"
  end
  seen_resources[path] = true
end

# ── 4. Check required files exist ──
required = [
  "QuanLyChiTieu/Info.plist",
  "QuanLyChiTieu/GoogleService-Info.plist",
]
required.each do |file|
  full = File.join(SOURCE_ROOT, file)
  unless File.exist?(full)
    errors << "Required file missing: #{file}"
  end
end

# ── 5. Check Swift files > 300 lines ──
Dir.glob(File.join(SOURCE_ROOT, "QuanLyChiTieu", "**", "*.swift")).each do |f|
  lines = File.readlines(f).count
  if lines > 300
    rel = f.sub("#{SOURCE_ROOT}/", "")
    warnings << "#{rel} is #{lines} lines (max 300)"
  end
end

# ── Output ──
puts ""
if auto_fixed.any?
  puts green("Auto-fixed:")
  auto_fixed.each { |f| puts "  #{green("✓")} #{f}" }
  puts ""
end

if errors.empty? && warnings.empty?
  puts green("✓ Project validation passed")
else
  if warnings.any?
    puts yellow("Warnings (#{warnings.count}):")
    warnings.each { |w| puts "  #{yellow("⚠")} #{w}" }
    puts ""
  end
  if errors.any?
    puts red("Errors (#{errors.count}):")
    errors.each { |e| puts "  #{red("✗")} #{e}" }
    puts ""
    exit 1
  end
end
