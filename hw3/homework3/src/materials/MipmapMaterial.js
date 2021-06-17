class MipmapMaterial extends Material {
    constructor(camera, vertexShader, fragmentShader) {
        super({
            'uMip': { type: 'texture', value: camera.fbo.textures[1] },
            'uWidth': { type: '1i', value: window.screen.width },
            'uHeight': { type: '1i', value: window.screen.height },
            'uLevel': { type: '1i', value: 1},
        }, [], vertexShader, fragmentShader, camera.fboMipmap);
    }
}

async function buildMipmapMaterial (camera, vertexPath, fragmentPath) {
    let vertexShader = await getShaderString(vertexPath);
    let fragmentShader = await getShaderString(fragmentPath);

    return new MipmapMaterial(camera, vertexShader, fragmentShader);
}