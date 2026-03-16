# Non-Linear Stretch Full-Screen Shader

This shader applies a **nonlinear horizontal stretch** to video and emulated content.  
It’s designed to make non-widescreen formats (4:3, 8:7, 10:9, etc.) feel more natural on widescreen displays (16:9, 16:10, 19.5:9, etc.) without the harsh uniform distortion of simple linear scaling.

Instead of stretching everything evenly, the shader warps the image outward in a smooth curve:
- The **center** stays relatively undistorted.  
- The **edges** gradually stretch more, filling the widescreen frame in a way that feels more natural with respect to the focal area.  

This effect works best when the main action is relatively centered, letting distortion live mostly in your peripheral vision.

---

## Parameters

- **Nonlinear Stretch Intensity** (`stretch_strength`)  
  Controls the overall amount of nonlinear warping (from linear to curved).  
  - *Low (0.0–0.2):* Mild — more linear, evenly stretched throughout.  
  - *Medium (0.3–0.5):* Balanced — central action feels natural, edges gently expand.  
  - *High (0.6–1.0):* Strong — center is strongly protected, edges are heavily stretched.  

- **Curve Profile** (`curve_profile`)  
  Controls how the warp curve is shaped. A higher value protects the center more while pushing distortion into the edges.  
  - *Low (0.2–0.4):* Smooth/Subtle — less center protection, more stretch throughout.  
  - *Medium (0.5–0.7):* Moderate — balanced protection vs. edge expansion.  
  - *High (0.8–1.0):* Extreme — minimal center distortion but dramatic edge stretch.  

- **Overscan X** (`overscan_x`)  
  Crops the input horizontally **after** the warp, removing black bars or pillarboxing some cores/games add. 
  - Higher values crop more aggressively. 
  
  - **Overscan Y** (`overscan_y`)  
  Crops the input vertically to remove letterboxing or unwanted black borders at the top/bottom.  
  - Useful for systems or cores that pad the vertical dimension with black edges.  
 

---

## Default / Recommended Starting Point

- **Nonlinear Stretch Intensity:** `0.40`  
- **Curve Profile:** `0.60`  
- **Overscan X:** `0.01`  
- **Overscan Y:** `0.00`

These defaults preserve the center well, expand to fill the edges naturally, and remove most black pillars.

---

## Usage

1. Drop the shader (`.slang`) and preset (`.slangp`) into your `shaders/` folder.  
2. Load it via RetroArch or any Slang-compatible frontend.  
3. Adjust parameters in real time to your preferences.

---

## Why Nonlinear?

Classic content was authored for ~4:3 displays. On modern widescreens, the usual options are:  
- **Black bars** (pillarboxing), which wastes screen space and looks foreign to the device, or…  
- **Linear stretch**, which distorts everything equally (making objects and characters look wider/fatter).  

This shader offers a middle ground: it **fills the screen** while keeping the central action natural, pushing distortion into the periphery where it’s less noticeable.

---

## Samples

### RAD RACER (NES/FC):
**Non-Linear Stretch:** 
_(with Y-Overscan Clipping saved in [per game] shader settings):_
<img width="1728" height="1117" alt="Image" src="https://github.com/user-attachments/assets/691f1c94-a47c-4404-8b88-1891a41e9e2a" />

Regular Scaling _[Scaling Aspect Ratio:  Core-Provided] (No Stretch):_
<img width="1728" height="1117" alt="Image" src="https://github.com/user-attachments/assets/8fb7b35c-3ca1-4fd9-997f-246f0efa7405" />

Linear Stretch _(Scaling Aspect Ratio: Full)_
<img width="1728" height="1117" alt="Image" src="https://github.com/user-attachments/assets/38ea56c3-f8f4-4aae-98de-1824299ba77d" />


### CHRONO TRIGGER (SNES/SFC):
**Non-Linear Stretch:** 
<img width="1728" height="1117" alt="Image" src="https://github.com/user-attachments/assets/7aa73781-3ed2-413a-b67c-b4a18b894c4c" />

Regular Scaling _[ScalingAspect Ratio: Core-Provided] (No Stretch):_
<img width="1728" height="1117" alt="Image" src="https://github.com/user-attachments/assets/0f485eda-4e07-4ccd-8468-3557db9b8dd1" />

Linear Stretch _(Scaling Aspect Ratio: Full)_
<img width="1728" height="1117" alt="Image" src="https://github.com/user-attachments/assets/9b001ba7-75dd-40ae-b63a-99b4ddb43739" />


---

## Changelog
- **v1.0.3** 
  - Added Debug Overlay Grid option visualize the live warp being applied to the video output.
- **v1.0.2**  
  - Added **Overscan Y** parameter (vertical crop) to remove letterboxing or unwanted top/bottom borders. Default set to `0.00` 
- **v1.0.0**  
  - First stable release.  
  - Full-width guarantee without reintroducing pillarboxing.  
  - Added **Overscan X** (post-warp crop) to handle black edge mattes.  
  - Tuned default values to: `Stretch 0.40`, `Curve 0.60`, `Overscan X 0.01`.  

---

## License

[MIT](LICENSE)
