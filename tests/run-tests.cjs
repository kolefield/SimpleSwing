const fs = require('fs');
const path = require('path');
const runtime = require('fengari-web');
const root = path.resolve(__dirname, '..');
const addon = root;

function files(dir) {
    return fs.readdirSync(dir, {withFileTypes: true}).flatMap(entry =>
        entry.isDirectory() ? (['Libs'].includes(entry.name) || dir !== addon ? files(path.join(dir, entry.name)) : []) : [path.join(dir, entry.name)]);
}
function quote(value) {
    if (value.includes(']====]')) throw new Error('Unexpected delimiter');
    return '[====[' + value + ']====]';
}
try {
    const lua = files(addon).filter(file => file.endsWith('.lua'));
    for (const file of lua) runtime.load(fs.readFileSync(file, 'utf8'), '@' + file);
    const sources = ['Timer.lua', 'SimpleSwing.lua', 'Libs/LibEditMode/widgets/coords.lua'].map(file =>
        '[ ' + quote(file) + ' ] = ' + quote(fs.readFileSync(path.join(addon, file), 'utf8'))).join(',\n');
    const preamble = 'local sources = {' + sources + '}\nfunction LoadSource(name, ns) return assert(load(sources[name], "@" .. name))("SimpleSwing", ns) end\n';
    const result = runtime.load(preamble + fs.readFileSync(path.join(root, 'tests/tests.lua'), 'utf8'), '@tests')();
    // Check packaging paths, including every nested XML script, before installation.
    const toc = fs.readFileSync(path.join(addon, 'SimpleSwing.toc'), 'utf8');
    for (const entry of toc.split(/\r?\n/).filter(line => line.trim() && !line.startsWith('#'))) {
        if (!fs.existsSync(path.join(addon, entry.trim().replaceAll('\\', '/')))) throw new Error('Missing TOC file: ' + entry);
    }
    for (const xml of files(addon).filter(file => file.endsWith('.xml'))) {
        const source = fs.readFileSync(xml, 'utf8');
        for (const match of source.matchAll(/file=['"]([^'"]+)['"]/g)) {
            if (!fs.existsSync(path.join(path.dirname(xml), match[1].replaceAll('\\', '/')))) throw new Error('Missing XML script: ' + match[1]);
        }
    }
    console.log(`${lua.length} Lua files compiled. All TOC/XML file references resolve.\n${result}\n`);
} catch(error) {
    console.log(String(error.stack || error));
    process.exitCode = 1;
}
