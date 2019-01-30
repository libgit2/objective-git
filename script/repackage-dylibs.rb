#!/usr/bin/ruby

# This script looks up an executable's list of shared libraries, copies
# non-standard ones (ie. anything not under /usr or /System/) into the target's
# bundle and updates the executable install_name to point to the "packaged"
# version.

# Usage:
# Add the script as a Run Script build phase in the target using Xcode.

# FIXMEs:
# - only handles dylibs
# - only tested against a framework target
# - doesn't care about codesigning


require 'fileutils'
require 'ostruct'

def err(msg)
  puts "error: " + msg
  exit 1
end

def warn(msg)
  puts "warning: " + msg
end

def note(msg)
  puts "note: " + msg
end

envvars = %w(
  TARGET_BUILD_DIR
  EXECUTABLE_PATH
  FRAMEWORKS_FOLDER_PATH
)

envvars.each do |var|
  raise "Must be run in an Xcode Run Phase" unless ENV[var]
  Kernel.const_set var, ENV[var]
end

TARGET_EXECUTABLE_PATH = File.join(TARGET_BUILD_DIR, EXECUTABLE_PATH)
TARGET_FRAMEWORKS_PATH = File.join(TARGET_BUILD_DIR, FRAMEWORKS_FOLDER_PATH)

def extract_link_dependencies(executable)
  deps = `otool -L #{executable}`

  lines = deps.split("\n").map(&:strip)
  lines.shift
  # lines.shift
  lines.map do |dep|
    path, compat, current = /^(.*) \(compatibility version (.*), current version (.*)\)$/.match(dep)[1..3]
    err "Failed to parse #{dep}" if path.nil?

    dep = OpenStruct.new
    dep.is_self = (File.basename(path) == File.basename(executable))
    dep.executable = executable
    dep.install_name = path
    dep.current_version = current
    dep.compat_version = compat
    dep.type = File.extname(path)
    dep.name = File.basename(path)
    dep.is_packaged = !!(dep.install_name =~ /^@rpath/)
    dep.path = if dep.install_name =~ /^@rpath/
      File.join(TARGET_FRAMEWORKS_PATH, dep.name)
    else
      dep.install_name
    end

    dep
  end
end

def repackage_dependency(dep)
  return if dep.is_self or dep.is_packaged or dep.path =~ /^(\/usr\/lib|\/System\/Library)/

  note "Packaging #{dep.name}…"

  FileUtils.mkdir(TARGET_FRAMEWORKS_PATH) unless Dir.exist?(TARGET_FRAMEWORKS_PATH)
  packaged_path = File.join(TARGET_FRAMEWORKS_PATH, dep.name)

  case dep.type
  when ".dylib"
    if File.exist? packaged_path
      warn "#{dep.path} already in Frameworks directory, removing"
      FileUtils.rm packaged_path
    end

    note "Copying #{dep[:path]} to TARGET_FRAMEWORKS_PATH"
    FileUtils.cp dep[:path], TARGET_FRAMEWORKS_PATH
    FileUtils.chmod "u=rw", packaged_path

    out = `install_name_tool -change #{dep.path} "@rpath/#{dep.name}" #{dep.executable}`
    if $? != 0
      err "install_name_tool failed with error #{$?}:\n#{out}"
    end

    dep.path = packaged_path
    dep.install_name = "@rpath/#{dep.name}"
    dep.is_packaged = true
  else
    warn "Unhandled type #{dep.type} for #{dep.path}, ignoring"
  end
end

def fix_install_id(dep)
  note "Fixing #{dep.name} install_name id…"
  out = `install_name_tool -id @rpath/#{dep.name} #{dep.executable}`
  if $? != 0
    err "install_name_tool failed with error #{$?}:\n#{out}"
  end
end

deps = extract_link_dependencies(TARGET_EXECUTABLE_PATH)
while (dep = deps.shift) do
  repackage_dependency dep
  fix_install_id dep if dep.is_self and dep.executable != TARGET_EXECUTABLE_PATH
  deps += extract_link_dependencies(dep[:path]) if dep.is_packaged and not dep.is_self
end

note "Packaging done"
exit 0
