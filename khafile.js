const project = new Project('quirk-boilerplate');

// alternative to project.addAssets('assets/**');
project.addAssets('assets/images/**/*.png');
project.addAssets('assets/data/**/*.json');
project.addAssets('assets/data/**/*.ldtk');
project.addAssets('assets/data/**/*.tmx');
project.addAssets('assets/music/**/*.wav');
project.addAssets('assets/audio/**/*.wav');
project.addAssets('assets/fonts/**/*.ttf');
project.addAssets('assets/fonts/**/*.fnt');
project.addAssets('assets/fonts/**/*.png');
project.addAssets('assets/index.html');

project.addShaders('shaders/**');
project.addSources('src');
// project.addDefine('debug_physics');
// project.addDefine('is_ng');
// project.addLibrary('newgrounds');

project.addDefine('kha_html5_disable_automatic_size_adjust');

// to send metrics locally or live, if at all.
project.addDefine('sends_metrics');
project.addDefine('localhost');

resolve(project);
