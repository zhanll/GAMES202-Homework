class PhongMaterial extends Material {

    constructor(color, specular, lights, translate, scale, vertexShader, fragmentShader) {
        let uniforms = {
            // Phong
            'uSampler': { type: 'texture', value: color },
            'uKs': { type: '3fv', value: specular },
        };

        for(let l=0; l<lights.length; ++l){
            let namePos = 'uLightPos[' + l + ']';
            uniforms[namePos] = { type: '3fv', value: lights[l].lightPos };

            let nameIntensity = 'uLightIntensity[' + l + ']';
            uniforms[nameIntensity] = { type: '3fv', value: lights[l].mat.GetIntensity() };

            let nameShadwoMap = 'uShadowMap[' + l + ']';
            uniforms[nameShadwoMap] = { type: 'texture', value: lights[l].fbo };

            let nameMVP = 'uLightMVP[' + l + ']';
            uniforms[nameMVP] = { type: 'matrix4fv', value: lights[l].CalcLightMVP(translate, scale) };
        }

        super(uniforms, [], vertexShader, fragmentShader);
    }
}

async function buildPhongMaterial(color, specular, lights, translate, scale, vertexPath, fragmentPath) {


    let vertexShader = await getShaderString(vertexPath);
    let fragmentShader = await getShaderString(fragmentPath);

    return new PhongMaterial(color, specular, lights, translate, scale, vertexShader, fragmentShader);

}