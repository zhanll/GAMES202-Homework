#include "denoiser.h"

Denoiser::Denoiser() : m_useTemportal(false) {}

void Denoiser::Reprojection(const FrameInfo &frameInfo) {
    int height = m_accColor.m_height;
    int width = m_accColor.m_width;
    Matrix4x4 preWorldToScreen =
        m_preFrameInfo.m_matrix[m_preFrameInfo.m_matrix.size() - 1];
    Matrix4x4 preWorldToCamera =
        m_preFrameInfo.m_matrix[m_preFrameInfo.m_matrix.size() - 2];
#pragma omp parallel for
    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            // TODO: Reproject
            m_valid(x, y) = false;
            m_misc(x, y) = Float3(0.f);

            int ID = static_cast<int>( frameInfo.m_id(x, y) );
            if (ID < 0 || ID >= frameInfo.m_matrix.size() - 2)
            {
                continue;
            }

            Matrix4x4 M = frameInfo.m_matrix[ID];
            Matrix4x4 M_inv = Inverse(M);
            Matrix4x4 M_0 = m_preFrameInfo.m_matrix[ID];

            Float3 P_world = frameInfo.m_position(x, y);
            Float3 P_m0 = M_0(M_inv(P_world, Float3::EType::Point), Float3::EType::Point);
            Float3 P0_camera = preWorldToCamera(P_m0, Float3::EType::Point);
            if (P0_camera.x < -1 || P0_camera.x > 1 ||
                P0_camera.y < -1 || P0_camera.y > 1 ||
                P0_camera.z < -1 || P0_camera.z > 1)
            {
                continue;
            }

            Float3 P0_screen = preWorldToScreen(P_m0, Float3::EType::Point);
            int X_screen = static_cast<int>(P0_screen.x);
            int Y_screen = static_cast<int>(P0_screen.y);
            if (X_screen < 0 || X_screen >= width ||
                Y_screen < 0 || Y_screen >= height)
            {
                continue;
            }

            int ID_0 = static_cast<int>(m_preFrameInfo.m_id(X_screen, Y_screen));
            if (ID != ID_0)
            {
                continue;
            }

            m_misc(x, y) = m_preFrameInfo.m_beauty(X_screen, Y_screen);
        }
    }
    std::swap(m_misc, m_accColor);
}

void Denoiser::TemporalAccumulation(const Buffer2D<Float3> &curFilteredColor) {
    int height = m_accColor.m_height;
    int width = m_accColor.m_width;
    int kernelRadius = 3;
#pragma omp parallel for
    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            // TODO: Temporal clamp
            Float3 color = m_accColor(x, y);

            if (m_valid(x, y))
            {
                int X_min = std::clamp(x - kernelRadius, 0, width);
                int X_max = std::clamp(x + kernelRadius, 0, width);
                int Y_min = std::clamp(y - kernelRadius, 0, height);
                int Y_max = std::clamp(y + kernelRadius, 0, height);

                Float3 C_sum(0.f);
                int cnt = 0;
                for (int X_k = X_min; X_k < X_max; ++X_k) {
                    for (int Y_k = Y_min; Y_k < Y_max; ++Y_k) {
                        ++cnt;
                        C_sum += curFilteredColor(X_k, Y_k);
                    }
                }

                if (cnt > 0)
                {
                    Float3 avg = C_sum / cnt;
                    Float3 vrt(0.f);

                    for (int X_k = X_min; X_k < X_max; ++X_k) {
                        for (int Y_k = Y_min; Y_k < Y_max; ++Y_k) {
                            vrt += SqrDistance(m_accColor(X_k, Y_k), avg);
                        }
                    }

                    vrt /= cnt;

                    color = Clamp(color, avg - vrt, avg + vrt);
                }
            }

            // TODO: Exponential moving average
            float alpha = 1.0f;
            if (m_valid(x, y))
            {
                alpha = m_alpha;
            }
            m_misc(x, y) = Lerp(color, curFilteredColor(x, y), alpha);
        }
    }
    std::swap(m_misc, m_accColor);
}

Buffer2D<Float3> Denoiser::Filter(const FrameInfo &frameInfo) {
    int height = frameInfo.m_beauty.m_height;
    int width = frameInfo.m_beauty.m_width;
    Buffer2D<Float3> filteredImage = CreateBuffer2D<Float3>(width, height);
    int kernelRadius = 16;

    // bonus: a-trous wavelet
    int passNum = 5;
    for (int iPass=0; iPass < passNum; ++iPass)
    {
#pragma omp parallel for
        for (int y = 0; y < height; y++) {
            for (int x = 0; x < width; x++) {
                // TODO: Joint bilateral filter
                // filteredImage(x, y) = frameInfo.m_beauty(x, y);

                Float3 C_0 = ( iPass==0 ? frameInfo.m_beauty(x, y) : filteredImage(x, y) );

                if (frameInfo.m_id(x, y) < 0) {
                    filteredImage(x, y) = C_0;
                    continue;
                }

                Float3 N_0 = frameInfo.m_normal(x, y);
                Float3 P_0 = frameInfo.m_position(x, y);

                int step = ( iPass == 0 ? 1 : 2 << (iPass - 1) );
                int Y_min = std::clamp(y - kernelRadius * step, 0, height - 1);
                int Y_max = std::clamp(y + kernelRadius * step, 0, height - 1);
                int X_min = std::clamp(x - kernelRadius * step, 0, width - 1);
                int X_max = std::clamp(x + kernelRadius * step, 0, width - 1);

                float W_sum = 0;
                Float3 C_sum(0.f);

                for (int K_x = X_min; K_x <= X_max; K_x+=step) {
                    for (int K_y = Y_min; K_y <= Y_max; K_y+=step) {
                        if (frameInfo.m_id(K_x, K_y) < 0) {
                            continue;
                        }

                        float a = (Sqr(x - K_x) + Sqr(y - K_y)) / (2 * Sqr(m_sigmaCoord));

                        Float3 C_k = ( iPass==0 ? frameInfo.m_beauty(K_x, K_y) : filteredImage(x, y) );
                        float b = SqrDistance(C_0, C_k) / (2 * Sqr(m_sigmaColor));

                        Float3 N_k = frameInfo.m_normal(K_x, K_y);
                        float D_n = SafeAcos(Dot(N_0, N_k));
                        float c = Sqr(D_n) / (2 * Sqr(m_sigmaNormal));

                        Float3 P_k = frameInfo.m_position(K_x, K_y);
                        float D_p = 1.0f;
                        if (SqrDistance(P_0, P_k) > 0.0001f) {
                            Float3 P = Normalize(P_k - P_0);
                            D_p = Dot(N_k, P);
                        }
                        float d = Sqr(D_p) / (2 * Sqr(m_sigmaPlane));

                        float w = std::expf(-a - b - c - d);
                        W_sum += w;
                        C_sum += C_k * w;
                    }
                }

                filteredImage(x, y) = W_sum < 0.0001f ? C_0 : C_sum / W_sum;
            }
        }
    }
    
    return filteredImage;
}

void Denoiser::Init(const FrameInfo &frameInfo, const Buffer2D<Float3> &filteredColor) {
    m_accColor.Copy(filteredColor);
    int height = m_accColor.m_height;
    int width = m_accColor.m_width;
    m_misc = CreateBuffer2D<Float3>(width, height);
    m_valid = CreateBuffer2D<bool>(width, height);
}

void Denoiser::Maintain(const FrameInfo &frameInfo) { m_preFrameInfo = frameInfo; }

Buffer2D<Float3> Denoiser::ProcessFrame(const FrameInfo &frameInfo) {
    // Filter current frame
    Buffer2D<Float3> filteredColor;
    filteredColor = Filter(frameInfo);

    // Reproject previous frame color to current
    if (m_useTemportal) {
        Reprojection(frameInfo);
        TemporalAccumulation(filteredColor);
    } else {
        Init(frameInfo, filteredColor);
    }

    // Maintain
    Maintain(frameInfo);
    if (!m_useTemportal) {
        m_useTemportal = true;
    }
    return m_accColor;
}
