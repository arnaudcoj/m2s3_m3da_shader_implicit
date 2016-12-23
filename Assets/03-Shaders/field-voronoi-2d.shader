Shader "Custom/VoronoiField2d" {
	Properties {
		_Positions ("Positions", 2D) = "white" {}
	    _ColorRamp ("Color Ramp", 2D) = "white" {}
	}
	
	SubShader {
	    Pass {
	    	CGPROGRAM
			#pragma vertex vert
			#pragma fragment fieldRenderer
			#pragma only_renderers d3d9
			#pragma target 3.0
			
			#include "UnityCG.cginc"
			
			sampler2D _Positions ; 
			sampler2D _ColorRamp ;
			
			struct v2f {
			    float4  pos : SV_POSITION;
			    float4  uv : TEXCOORD0;
			};
			
			v2f vert (appdata_base v)
			{
			    v2f o;
			    o.pos = mul (UNITY_MATRIX_MVP, v.vertex);
			    o.uv = v.texcoord;
			    return o;
			}

			// Return the primitive position in xy and material/color in z. 
			// The positions xy are between -1 et 1.
			// The primitive material is returned in the z component.
			float3 getPrimitive(int i){
				float4 c=tex2D(_Positions, float2((1.0*i)/32,0)) ;
				c.xy = 2*(c.xy-float2(0.5,0.5)) ;
				return c.xyz ; 
			}
						
			// Return the field value in x and the material color in y
			float2 evaluateFieldAt(float2 pos)
			{
				/// Mettez ici votre code qui calcule le minimum des fonctions de distance 
				/// de l'ensemble de primitives. 
				
				/// La valeur retourné sera encodée de la manière suivante:
				/// x == la valeur de la plus petite distance rencontrée
				/// y == l'indice ou la couleur de la primitive associée à cette distance. 
				return float2(0,0) ;
			}
			
			float4 fieldRenderer(v2f ver) : COLOR
			{
				// get the position from the uv coordinates between (-1 et 1) 
				float2 p={(1-ver.uv[0]-0.5f)*2f, 1f*(1-ver.uv[1]-0.5f)*2f} ;
				
				float2 fieldValue=evaluateFieldAt(p) ;
				
				// mettre ici votre code qui affiche une couleur dépendant de la primitive
				// selectionné par le calcul du diagramme de Voronoi. 
				return float4(0.5,0,0.5,0) ;
			}
			ENDCG	
	    }
	}
	Fallback "VertexLit"
}
