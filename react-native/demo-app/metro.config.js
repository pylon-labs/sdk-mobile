const { getDefaultConfig } = require('expo/metro-config');
const path = require('path');

const config = getDefaultConfig(__dirname);

// Add the parent directory to watchFolders so Metro can find the package
const parentDir = path.resolve(__dirname, '..');
config.watchFolders = [parentDir];

// Configure resolver to handle the package
config.resolver.nodeModulesPaths = [
  path.resolve(__dirname, 'node_modules'),
  path.resolve(parentDir, 'node_modules'),
];

module.exports = config;

