#!/usr/bin/env node
// [Global package listing problems](https://github.com/volta-cli/volta/issues/1157)
import * as path from 'node:path';
import { ok as assert } from 'node:assert/strict';
import { readdir, readFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
export function isMainModule(importMeta) {
    const filePath = fileURLToPath(importMeta.url);
    return process.argv[1] === filePath;
}
/** Search all subdirectories, yielding matching file entries */
export async function* findFiles(dir, regexpFilter) {
    for (const entry of await readdir(dir, { withFileTypes: true })) {
        const fPath = path.resolve(dir, entry.name);
        if (entry.isDirectory()) {
            yield* findFiles(fPath, regexpFilter);
            continue;
        }
        if (regexpFilter && !regexpFilter.test(entry.name))
            continue;
        yield Object.assign(entry, { path: fPath });
    }
}
export function getVoltaHome() {
    const voltaHome = process.env.VOLTA_HOME;
    assert(voltaHome, 'env:VOLTA_HOME not found');
    return path.resolve(voltaHome);
}
export function assertIsValidPackageInfo(value) {
    assert(typeof value === 'object' && value !== null && !Array.isArray(value), 'Expected argument to be non-null, non-array object');
    assert(typeof value.name === 'string', 'Expected typeof pkg.name to be "string"');
    assert(typeof value.version === 'string', 'Expected typeof pkg.version to be "string"');
    assert(typeof value.manager === 'string', 'Expected typeof pkg.manager to be "string"');
    const { platform } = value;
    assert((typeof platform === 'object'
        && platform !== null
        && !Array.isArray(platform)), 'Expected pkg.platform to be non-null, non-array object');
    assert(typeof platform.node === 'string' || platform.node === null, 'Expected typeof pkg.platform.node to be "string" or null');
    assert(typeof platform.npm === 'string' || platform.npm === null, 'Expected typeof pkg.platform.npm to be "string" or null');
    assert(typeof platform.yarn === 'string' || platform.yarn === null, 'Expected typeof pkg.platform.yarn to be "string" or null');
    const { bins } = value;
    assert(Array.isArray(bins), 'Expected pkg.bins to be array');
    for (const bin of bins) {
        assert(typeof bin === 'string', 'Expected pkg.bins to be array of strings');
    }
}
export async function getInstalledPackages() {
    const pkgs = [];
    const userPkgsDir = path.join(getVoltaHome(), 'tools', 'user', 'packages');
    const regExpHasJsonExt = /\.json$/;
    const textFileOpts = { encoding: 'utf-8' };
    for await (const entry of findFiles(userPkgsDir, regExpHasJsonExt)) {
        const pkgInfo = JSON.parse(await readFile(entry.path, textFileOpts));
        assertIsValidPackageInfo(pkgInfo);
        pkgs.push(pkgInfo);
    }
    return pkgs.sort(({ name: a }, { name: b }) => a < b ? -1 : a > b ? 1 : 0);
}
async function main() {
    const pkgs = await getInstalledPackages();
    if (process.argv[2] === '--json') {
        const json = JSON.stringify(pkgs, null, 2);
        console.log(json);
        process.exit(0);
    }
    for (const pkg of pkgs) {
        let formatted = `${pkg.name} (${pkg.version})`;
        if (pkg.bins.length > 0) {
            for (const bin of pkg.bins)
                formatted += `\n  ${bin}`;
        }
        console.log(formatted);
    }
}
if (isMainModule(import.meta))
    main();
