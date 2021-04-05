class PhongMaterial extends Material {

    constructor(color, specular, light, translate, scale, vertexShader, fragmentShader) {
        let lightMVP = light.CalcLightMVP(translate, scale);
        let lightIntensity = light.mat.GetIntensity();

        super({
            // Phong
            'uSampler': { type: 'texture', value: color },
            'uKs': { type: '3fv', value: specular },
            'uLightIntensity': { type: '3fv', value: lightIntensity },
            // Shadow
            'uShadowMap': { type: 'texture', value: light.fbo },
            'uLightMVP': { type: 'matrix4fv', value: lightMVP },

        }, [], vertexShader, fragmentShader);

        this.scale = scale;
    }

    changeLight(light, translate) {
        let lightMVP = light.CalcLightMVP(translate, this.scale);
        let lightIntensity = light.mat.GetIntensity();

        this.uniforms['uLightIntensity'] = { type: '3fv', value: lightIntensity };
        this.uniforms['uShadowMap'] = { type: 'texture', value: light.fbo };
        this.uniforms['uLightMVP'] = { type: 'matrix4fv', value: lightMVP };
    }
}

async function buildPhongMaterial(color, specular, light, translate, scale, vertexPath, fragmentPath) {


    let vertexShader = await getShaderString(vertexPath);
    let fragmentShader = await getShaderString(fragmentPath);

    return new PhongMaterial(color, specular, light, translate, scale, vertexShader, fragmentShader);

}