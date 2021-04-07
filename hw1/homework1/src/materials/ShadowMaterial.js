class ShadowMaterial extends Material {

    constructor(lights, translate, scale, vertexShader, fragmentShader) {
        let uniforms = {};
        let fbo = [];
        for(let l=0; l<lights.length; ++l) {
            let namePos = 'uLightPos[' + l + ']';
            uniforms[namePos] = { type: '3fv', value: lights[l].lightPos };

            let nameMVP = 'uLightMVP[' + l + ']';
            uniforms[nameMVP] = { type: 'matrix4fv', value: lights[l].CalcLightMVP(translate, scale) };

            fbo.push( lights[l].fbo );
        }

        super(uniforms, [], vertexShader, fragmentShader, fbo);
    }
}

async function buildShadowMaterial(lights, translate, scale, vertexPath, fragmentPath) {


    let vertexShader = await getShaderString(vertexPath);
    let fragmentShader = await getShaderString(fragmentPath);

    return new ShadowMaterial(lights, translate, scale, vertexShader, fragmentShader);

}