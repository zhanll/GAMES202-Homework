function getRotationPrecomputeL(precompute_L, rotationMatrix){
	let matRotation = mat4Matrix2mathMatrix(rotationMatrix);

	let x1 = [precompute_L[1], precompute_L[2], precompute_L[3]];
	let x1_t = math.transpose(x1);

	let x2 = [precompute_L[4], precompute_L[5], precompute_L[6], precompute_L[7], precompute_L[8]];
	let x2_t = math.transpose(x2);
	
	let R_x1 = math.multiply(computeSquareMatrix_3by3(matRotation), x1_t).toArray();
	let R_x2 = math.multiply(computeSquareMatrix_5by5(matRotation), x2_t).toArray();

	let result = mat3.fromValues(
		precompute_L[0], R_x1[0], R_x1[1],
		R_x1[2], R_x2[0], R_x2[1],
		R_x2[2], R_x2[3], R_x2[4]
	);
	return result;
}

function computeSquareMatrix_3by3(rotationMatrix){ // 计算方阵SA(-1) 3*3 
	
	// 1、pick ni - {ni}
	let n1 = [1, 0, 0, 0]; let n2 = [0, 0, 1, 0]; let n3 = [0, 1, 0, 0];

	let n1_t = math.transpose(n1);
	let n2_t = math.transpose(n2);
	let n3_t = math.transpose(n3);

	// 2、{P(ni)} - A  A_inverse
	let P_n1 = SHEval(n1_t[0], n1_t[1], n1_t[2], 3);
	let P_n2 = SHEval(n2_t[0], n2_t[1], n2_t[2], 3);
	let P_n3 = SHEval(n3_t[0], n3_t[1], n3_t[2], 3);

	let A = math.matrix([[P_n1[1], P_n2[1], P_n3[1]],
						 [P_n1[2], P_n2[2], P_n3[2]],
						 [P_n1[3], P_n2[3], P_n3[3]]]);
	let A_inverse = math.inv(A);

	// 3、用 R 旋转 ni - {R(ni)}
	let R_n1 = math.multiply(rotationMatrix, n1_t).toArray();
	let R_n2 = math.multiply(rotationMatrix, n2_t).toArray();
	let R_n3 = math.multiply(rotationMatrix, n3_t).toArray();

	// 4、R(ni) SH投影 - S
	let S1 = SHEval(R_n1[0], R_n1[1], R_n1[2], 3);
	let S2 = SHEval(R_n2[0], R_n2[1], R_n2[2], 3);
	let S3 = SHEval(R_n3[0], R_n3[1], R_n3[2], 3);

	let S = math.matrix([[S1[1], S2[1], S3[1]],
						 [S1[2], S2[2], S3[2]],
						 [S1[3], S2[3], S3[3]]]);

	// 5、S*A_inverse
	return math.multiply(S, A_inverse);
}

function computeSquareMatrix_5by5(rotationMatrix){ // 计算方阵SA(-1) 5*5
	
	// 1、pick ni - {ni}
	let k = 1 / math.sqrt(2);
	let n1 = [1, 0, 0, 0]; let n2 = [0, 0, 1, 0]; let n3 = [k, k, 0, 0]; 
	let n4 = [k, 0, k, 0]; let n5 = [0, k, k, 0];

	let n1_t = math.transpose(n1);
	let n2_t = math.transpose(n2);
	let n3_t = math.transpose(n3);
	let n4_t = math.transpose(n4);
	let n5_t = math.transpose(n5);

	// 2、{P(ni)} - A  A_inverse
	let P_n1 = SHEval(n1_t[0], n1_t[1], n1_t[2], 5);
	let P_n2 = SHEval(n2_t[0], n2_t[1], n2_t[2], 5);
	let P_n3 = SHEval(n3_t[0], n3_t[1], n3_t[2], 5);
	let P_n4 = SHEval(n4_t[0], n4_t[1], n4_t[2], 5);
	let P_n5 = SHEval(n5_t[0], n5_t[1], n5_t[2], 5);

	let A = math.matrix([[P_n1[4], P_n2[4], P_n3[4], P_n4[4], P_n5[4]],
						 [P_n1[5], P_n2[5], P_n3[5], P_n4[5], P_n5[5]],
						 [P_n1[6], P_n2[6], P_n3[6], P_n4[6], P_n5[6]],
						 [P_n1[7], P_n2[7], P_n3[7], P_n4[7], P_n5[7]],
						 [P_n1[8], P_n2[8], P_n3[8], P_n4[8], P_n5[8]]]);
	let A_inverse = math.inv(A);

	// 3、用 R 旋转 ni - {R(ni)}
	let R_n1 = math.multiply(rotationMatrix, n1_t).toArray();
	let R_n2 = math.multiply(rotationMatrix, n2_t).toArray();
	let R_n3 = math.multiply(rotationMatrix, n3_t).toArray();
	let R_n4 = math.multiply(rotationMatrix, n4_t).toArray();
	let R_n5 = math.multiply(rotationMatrix, n5_t).toArray();

	// 4、R(ni) SH投影 - S
	let S1 = SHEval(R_n1[0], R_n1[1], R_n1[2], 5);
	let S2 = SHEval(R_n2[0], R_n2[1], R_n2[2], 5);
	let S3 = SHEval(R_n3[0], R_n3[1], R_n3[2], 5);
	let S4 = SHEval(R_n4[0], R_n4[1], R_n4[2], 5);
	let S5 = SHEval(R_n5[0], R_n5[1], R_n5[2], 5);

	let S = math.matrix([[S1[4], S2[4], S3[4], S4[4], S5[4]],
						 [S1[5], S2[5], S3[5], S4[5], S5[5]],
						 [S1[6], S2[6], S3[6], S4[6], S5[6]],
						 [S1[7], S2[7], S3[7], S4[7], S5[7]],
						 [S1[8], S2[8], S3[8], S4[8], S5[8]]]);

	// 5、S*A_inverse
	return math.multiply(S, A_inverse);
}

function mat4Matrix2mathMatrix(rotationMatrix){

	let mathMatrix = [];
	for(let i = 0; i < 4; i++){
		let r = [];
		for(let j = 0; j < 4; j++){
			r.push(rotationMatrix[i*4+j]);
		}
		mathMatrix.push(r);
	}
	let result = math.matrix(mathMatrix);
	return math.transpose(result);

}

function getMat3ValueFromRGB(precomputeL){

    let colorMat3 = [];
    for(var i = 0; i<3; i++){
        colorMat3[i] = mat3.fromValues( precomputeL[0][i], precomputeL[1][i], precomputeL[2][i],
										precomputeL[3][i], precomputeL[4][i], precomputeL[5][i],
										precomputeL[6][i], precomputeL[7][i], precomputeL[8][i] ); 
	}
    return colorMat3;
}