Shader "Custom/DistanceFieldRenderer" {
	Properties {
		_Positions ("Positions", 2D) = "white" { } 
	    _ColorRamp ("Color Ramp", 2D) = "white" {}
	    _Mode ("Mode", Float) = 0
	    _DoUnion("DoUnion", Int) = 1
	}
	
	SubShader {
	    Pass {
	    	CGPROGRAM
			#pragma vertex vert
			#pragma fragment sphereTracer
			#pragma only_renderers d3d9
			#pragma target 3.0
			
			#include "UnityCG.cginc"
			
			int _Mode ;
			int _DoUnion ; 
			sampler2D _Positions ; 
			sampler2D _ColorRamp ;
			
			/// Encode camera position and projections matrix... 
			uniform float4x4 _InvMVP;
			uniform float4x4 _MVP;
			uniform float _Near;
			uniform float _Far;
			uniform float4 _Result;
			uniform float _MTime;

			uniform float4 _EyePosition;
			uniform float3  _LightPos;
			
			struct v2f {
			    float4  pos : SV_POSITION;
			    float2  uv : TEXCOORD0;
			};
			
			v2f vert (appdata_base v)
			{
			    v2f o;
			    o.pos = mul (UNITY_MATRIX_MVP, v.vertex);
			    o.uv = v.texcoord;
			    return o;
			}
			
		

			///////////////////// Here are some distance function //////////////////////
			float sdSphere(float3 v,float radius)
			{
				return length(v)-radius;
			}
			
			float sdBox(float3 v,float radius)
			{
				return length(v)-radius;
			}
			
			float sdPlane(float3 p, float4 n)
			{
  				// n must be normalized
  				return dot(p,n.xyz) + n.w ;
			}

			float udRoundBox(float3 p, float3 b, float r)
			{
				return length(max(abs(p)-b,0.0))-r;
			}
			
			///// The distance evaluation is here...
			float2 sDistance(float3 pos){
				/// Mettre ICI le code nécessaire pour modéliser 
				/// l'union de deux sphères, la soustraction d'une boite et d'une sphère
				/// et un plan. Vous pouvez utiliser les fonctions de distances 
				/// présenté dans: http://www.iquilezles.org/www/articles/distfunctions/distfunctions.htms 
				return sdSphere(pos-float3(0.0,0.0,0.0), 1.0);
			}

			// Return the normal of the distance field 
			// at a given point using first order, centered, finite derivatives.
			float3 sNormal(float3 pos, float eps){
				/// Mettre ici votre code qui calcule la normale du champ de distance
				///  par la méthode des différences finies (eps étant le pas de la différence finie). 
				float rx=sDistance(pos+float3(-eps, 0, 0));
				float ry=sDistance(pos+float3(0, -eps, 0));
				float rz=sDistance(pos+float3(0,0,-eps));
				float lx=sDistance(pos+float3(eps, 0, 0));
				float ly=sDistance(pos+float3(0, eps, 0));
				float lz=sDistance(pos+float3(0,0,eps));
				return float3((lx-rx)/2, (ly-ry)/2, (lz-rz)/2);
			}
				
			// Compute the amount of penumbra. This is computed 
			// by marching from the current position (ro) 
			// to the ray to the light source (rd) 
			// mint is the starting point on the ray
			// maxt is the end point (the light source location). 																																																		
			float shadow( float3 ro, float3 rd, float mint, float maxt )
			{
    			for( float t=mint; t < maxt; )
   		 		{
	        		float h = sDistance(ro + rd*t);
        			if( h<0.0001 )
            			return 0.3;
        			t += h;
    			}
    			return 1.0;
			}	
				
			// Compute the illumination using the classical
			// Phong lighting equation. 
			float3 lighting(float3 pos, float3 diffuseColor){
				float Ka=0.0;
				float Ks=1.0;
				float shininess=20;

				float3 emissive=float3(0,0,0);
				float3 ambiant=Ka*float3(1,1,1);

				float3 ld=_LightPos-pos;
				float3 N=normalize(sNormal(pos, 0.0001));
				float3 lightColor=float3(1,1,1);
				
				float diffuseTerm=max(dot(N, normalize(ld)),0);
				float3 diffuse=diffuseColor*lightColor*diffuseTerm;
				
				float3 V = normalize(_EyePosition - pos);
  				float3 H = normalize(ld + V);
				float specularLight = pow(max(dot(N, H), 0), shininess);
				if (diffuseTerm <= 0) 
					specularLight = 0;
				float3 specular = Ks * lightColor * specularLight;

				return diffuse+emissive+ambiant+specular;
			}
																																	
			half4 sphereTracer(v2f ver) : COLOR
			{
				// Generate the current Ray that we will march along.  
				// Take the x,y from the uv texture, center it and convert 
				// it into viewport coordinates 
				float4 pnear={(1-ver.uv[0]-0.5f)*2f, 1f*(1-ver.uv[1]-0.5f)*2f, -1f, 1f};
				float4 pfar={(1-ver.uv[0]-0.5f)*2f, 1f*(1-ver.uv[1]-0.5f)*2f,  1f, 1f};
				
				// Apply the inverse of the projection matrix to get world-coordinates from 
				// the viewport coordinates.  
				pnear=mul(_InvMVP, pnear) ;
			    pfar=mul(_InvMVP, pfar) ;

				// get the coordinates of the Ray endpoint in non homogeneous coordinates.  
			    float3 ppnear=pnear.xyz/pnear.w ;
			    float3 ppfar=pfar.xyz/pfar.w ;
			   			     
			   	// from the two end point we can compute the ray  
			    float3 dir=ppfar-ppnear ;			    
			    float  maxdist=length(dir) ;
			  	float3 vdir=normalize(dir) ;		  	

			    // cp is the initial position. 			    
			    float3 cp=ppnear ;
			    
			    float pdist=5f ;
			   	float mdist=pdist ;
			   	float cdist=0 ;
			   	float odist = 0 ;
			   	float c=0;
			   	
			   	float stepsize=maxdist/1024 ;
			   	int i = 0 ; 
			   	float ci = 0 ;
			   	for(i=0;i<1024;i++){
					// This function evaluates the distance to any object in the scene. 
			   		float2 r=sDistance(cp) ; 
				
					odist = r.x ;
					c = r.y ; 

					// if we are below a small distance we are "nearly" intersecting an object. 
					// and thus we return a yellow color. 
					if(odist < 0.0001)
					{		
						/// Changer le code ICI  pour visualiser la scène en utilisant 
						/// les fonction d'éclairages lighting/shadow ainsi que l'identifiant 
						/// de la matière codé dans la composante y retourné par la 
						/// fonction sDistance().  				
						return float4(1.0,1.0,0.0,1.0) ;
					}
				
					// if we touch the far plane of the camera we exit by 
					// displaying a gradient showing the number of iteration. 
					if(cdist > maxdist){
						return 1-i/50f;
					}
					
					if(mdist>odist)
						mdist=odist;
				
					/// Changer ICI  le code pour utiliser la distance retournée par la fonction de distance 
					/// afin d'accélérer la progression sur le rayon.
					cdist = cdist + stepsize ;
			   		cp=cp+(vdir*odist);
			    }
			
				// if we are here this means we made a large amount of iterations
				// without touching the object. 
			    return half4(1, 0, 1, 1.0);
			}
			ENDCG	
	    }
	}
	Fallback "VertexLit"
}
