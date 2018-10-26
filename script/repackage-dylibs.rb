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

def extract_link_dependencies
  deps = `otool -L #{TARGET_EXECUTABLE_PATH}`

  lines = deps.split("\n").map(&:strip)
  lines.shift
  lines.shift
  lines.map do |dep|
    path, compat, current = /^(.*) \(compatibility version (.*), current version (.*)\)$/.match(dep)[1..3]
    err "Failed to parse #{dep}" if path.nil?

    dep = OpenStruct.new
    dep.install_name = path
    dep.current_version = current
    dep.compat_version = compat
    dep.type = File.extname(path)
    dep.name = File.basename(path)
    dep.is_packaged = (dep.install_name =~ /^@rpath/)
    dep.path = if dep.install_name =~ /^@rpath/
      File.join(TARGET_FRAMEWORKS_PATH, dep.name)
    else
      dep.install_name
    end

    dep
  end
end

def repackage_dependency(dep)
  return if dep.is_packaged or dep.path =~ /^(\/usr\/lib|\/System\/Library)/

  note "Packaging #{dep.name}…"

  FileUtils.mkdir(TARGET_FRAMEWORKS_PATH) unless Dir.exist?(TARGET_FRAMEWORKS_PATH)

  case dep.type
  when ".dylib"
    if File.exist?(File.join(TARGET_FRAMEWORKS_PATH, dep.name))
      warn "#{dep.path} already in Frameworks directory, removing"
      FileUtils.rm File.join(TARGET_FRAMEWORKS_PATH, dep.name)
    end

    note "Copying #{dep[:path]} to TARGET_FRAMEWORKS_PATH"
    FileUtils.cp dep[:path], TARGET_FRAMEWORKS_PATH

    out = `install_name_tool -change #{dep.path} "@rpath/#{dep.name}" #{TARGET_EXECUTABLE_PATH}`
    if $? != 0
      err "install_name_tool failed with error #{$?}:\n#{out}"
    end

    dep.path = File.join(TARGET_FRAMEWORKS_PATH, dep.name)
    dep.install_name = "@rpath/#{dep.name}"
    dep.is_packaged = true

  else
    warn "Unhandled type #{dep.type} for #{dep.path}, ignoring"
  end
end

extract_link_dependencies.each do |dep|
  repackage_dependency dep
end

note "Packaging done"
exit 0
