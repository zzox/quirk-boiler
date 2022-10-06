const project = new Project('boilerplate');

project.addAssets('assets/**');
project.addShaders('shaders/**');
project.addSources('src');
project.addLibrary('astar');
// project.addDefine('debug_physics');

resolve(project);
