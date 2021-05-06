class EnvLightMaterial extends Material {
    
    constructor(vertexShader, fragmentShader) {

        super({
            'uPrecomputeLR': { type: 'matrix3fv', value: null },
            'uPrecomputeLG': { type: 'matrix3fv', value: null },
            'uPrecomputeLB': { type: 'matrix3fv', value: null }
        }, ['aPrecomputeLT'], vertexShader, fragmentShader, null);
    }
}

async function buildEnvLightMaterial(vertexPath, fragmentPath) {
    

    let vertexShader = await getShaderString(vertexPath);
    let fragmentShader = await getShaderString(fragmentPath);

    return new EnvLightMaterial(vertexShader, fragmentShader);

}