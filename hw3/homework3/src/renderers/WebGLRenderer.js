class WebGLRenderer {
    meshes = [];
    shadowMeshes = [];
    bufferMeshes = [];
    mipmapMeshes = [];
    lights = [];

    constructor(gl, camera) {
        this.gl = gl;
        this.camera = camera;
    }

    addLight(light) {
        this.lights.push({
            entity: light,
            meshRender: new MeshRender(this.gl, light.mesh, light.mat)
        });
    }
    addMeshRender(mesh) { this.meshes.push(mesh); }
    addShadowMeshRender(mesh) { this.shadowMeshes.push(mesh); }
    addBufferMeshRender(mesh) { this.bufferMeshes.push(mesh); }
    addMipmapMeshRender(mesh) { this.mipmapMeshes.push(mesh); }

    render() {
        console.assert(this.lights.length != 0, "No light");
        console.assert(this.lights.length == 1, "Multiple lights");
        var light = this.lights[0];

        const gl = this.gl;
        gl.clearColor(0.0, 0.0, 0.0, 1.0);
        gl.clearDepth(1.0);
        gl.enable(gl.DEPTH_TEST);
        gl.depthFunc(gl.LEQUAL);
        gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

        // Update parameters
        let lightVP = light.entity.CalcLightVP();
        let lightDir = light.entity.CalcShadingDirection();
        let updatedParamters = {
            "uLightVP": lightVP,
            "uLightDir": lightDir,
        };

        // Draw light
        light.meshRender.mesh.transform.translate = light.entity.lightPos;
        light.meshRender.draw(this.camera, null, updatedParamters);

        // Shadow pass
        gl.bindFramebuffer(gl.FRAMEBUFFER, light.entity.fbo);
        gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
        for (let i = 0; i < this.shadowMeshes.length; i++) {
            this.shadowMeshes[i].draw(this.camera, light.entity.fbo, updatedParamters);
            // this.shadowMeshes[i].draw(this.camera);
        }
        // return;

        // Buffer pass
        gl.bindFramebuffer(gl.FRAMEBUFFER, this.camera.fbo);
        gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
        for (let i = 0; i < this.bufferMeshes.length; i++) {
            this.bufferMeshes[i].draw(this.camera, this.camera.fbo, updatedParamters);
            // this.bufferMeshes[i].draw(this.camera);
        }
        // return

        // Mipmap pass
        let MIP_lEVEL = 7;
        for (let level = 1; level <= MIP_lEVEL; ++level) {
            updatedParamters['uLevel'] = level;

            if (level % 2 == 1) {

                if (level == 1) {
                    updatedParamters['uMip'] = this.camera.fbo.textures[1];
                } else {
                    updatedParamters['uMip'] = this.camera.fboMipmap2.textures[5];
                }

                gl.bindFramebuffer(gl.FRAMEBUFFER, this.camera.fboMipmap1);
                gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
                for (let i = 0; i < this.mipmapMeshes.length; i++) {
                    this.mipmapMeshes[i].draw(this.camera, this.camera.fboMipmap1, updatedParamters);
                }

            } else {

                updatedParamters['uMip'] = this.camera.fboMipmap1.textures[5];

                gl.bindFramebuffer(gl.FRAMEBUFFER, this.camera.fboMipmap2);
                gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
                for (let i = 0; i < this.mipmapMeshes.length; i++) {
                    this.mipmapMeshes[i].draw(this.camera, this.camera.fboMipmap2, updatedParamters);
                }
                
            }
        }

        // Camera pass
        gl.bindFramebuffer(gl.FRAMEBUFFER, null);
        gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
        for (let i = 0; i < this.meshes.length; i++) {
            this.meshes[i].draw(this.camera, null, updatedParamters);
        }
    }
}