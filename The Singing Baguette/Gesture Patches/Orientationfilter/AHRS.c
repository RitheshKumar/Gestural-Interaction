
 /*	
  
 "AHRS" Object for Max/Msp 6

 based on the public domain code :
  
  //=====================================================================================================
  // MadgwickAHRS.c
  //=====================================================================================================
  //
  // Implementation of Madgwick's IMU and AHRS algorithms.
  // See: http://www.x-io.co.uk/node/8#open_source_ahrs_and_imu_algorithms
  //
  // Date			Author          Notes
  // 29/09/2011	SOH Madgwick    Initial release
  // 02/10/2011	SOH Madgwick	Optimised for reduced CPU load
  // 19/02/2012	SOH Madgwick	Magnetometer measurement is normalised
  //
  //=====================================================================================================
  
  */

#include "ext.h"
#include "ext_common.h"
#include "ext_obex.h"		// required for new style Max object
#include <math.h>
#define PI 3.1415926535897932384626433832795

float pisur180;

typedef struct AHRS		// Data structure for this object
{ 
	t_object m_ob;      // Must always be the first field; used by Max
    float beta;         // 2 * proportional gain
    float Te;           // sampling period
    float q0;
    float q1;
    float q2;
    float q3;
    void *AxisAngle;       // outlet for axis-angle representation data list
    void *EulerAngles;     // outlet for Euler angles representation data list
} t_AHRS;

void *AHRS_class;				// Required. Global pointing to this class

//***********************************************************************************************************************************************//

void AHRS_assist(t_AHRS *AHRS, void *b, long msg, long arg, char *s);
void AHRS_list(t_AHRS *x, t_symbol *s, short ac, t_atom *av);
void *AHRS_new(double beta, double Te);
void AHRS_init(t_AHRS *x);
void AHRS_dump(t_AHRS *x);
void AHRS_free(t_AHRS *x);
float invSqrt(float x);

//***********************************************************************************************************************************************//

int C74_EXPORT main(void)
{
    t_class *c;

    c = class_new("AHRS", (method)AHRS_new, (method)AHRS_free, (short)sizeof(t_AHRS), (method)0L, A_DEFFLOAT, A_DEFFLOAT, 0);
    class_addmethod(c, (method)AHRS_list,   "list", A_GIMME, 0);
    class_addmethod(c, (method)AHRS_assist, "assist", A_CANT, 0);
    class_addmethod(c, (method)AHRS_init,   "init", A_CANT, 0);
    class_addmethod(c, (method)AHRS_dump,   "dump",0);
    class_register(CLASS_BOX, c);
    AHRS_class = c;
    pisur180 = (float)(PI/180.);
    post ("[AHRS object] version %s, - CNRS LMA - %s", "1.0", "2014 may");
    return 0;
}

//***********************************************************************************************************************************************//
//
//  Here we receive a list of data (acc, gyr, mag)
//  acc unit is g
//  gyr unit is °/s => it must be radians/s
//  the Madgwick's algorithm compute Euler angles.

void AHRS_list(t_AHRS *x, t_symbol *s, short ac, t_atom *argv)
{
    float ax = argv[0].a_w.w_float;
    float ay = argv[1].a_w.w_float;
    float az = argv[2].a_w.w_float;
    float gx = argv[3].a_w.w_float * pisur180;
    float gy = argv[4].a_w.w_float * pisur180;
    float gz = argv[5].a_w.w_float * pisur180;
    float mx = argv[6].a_w.w_float;
    float my = argv[7].a_w.w_float;
    float mz = argv[8].a_w.w_float;
    float q0 = x->q0;
    float q1 = x->q1;
    float q2 = x->q2;
    float q3 = x->q3;
    float beta = x->beta;
    float Te = x->Te;
    float recipNorm;
	float s0, s1, s2, s3;
	float qDot1, qDot2, qDot3, qDot4;
	float hx, hy;
	float _2q0mx, _2q0my, _2q0mz, _2q1mx, _2bx, _2bz, _4bx, _4bz, _2q0, _2q1, _2q2, _2q3, _2q0q2, _2q2q3, q0q0, q0q1, q0q2, q0q3, q1q1, q1q2, q1q3, q2q2, q2q3, q3q3;
    float angle;
    float ixe;
    float y;
    float z;
    float q0squared;
    float is;
    float si,si2;
    float co,co2;
    float t;
    float test;
    float heading, attitude, bank;
    t_atom myList[4];
	// Rate of change of quaternion from gyroscope
	qDot1 = 0.5f * (-q1 * gx - q2 * gy - q3 * gz);
	qDot2 = 0.5f *  (q0 * gx + q2 * gz - q3 * gy);
	qDot3 = 0.5f *  (q0 * gy - q1 * gz + q3 * gx);
	qDot4 = 0.5f *  (q0 * gz + q1 * gy - q2 * gx);
    
	// Compute feedback only if accelerometer measurement valid (avoids NaN in accelerometer normalisation)
	if(!((ax == 0.0f) && (ay == 0.0f) && (az == 0.0f))) {
        
		// Normalise accelerometer measurement
		recipNorm = invSqrt(ax * ax + ay * ay + az * az);
		ax *= recipNorm;
		ay *= recipNorm;
		az *= recipNorm;
        
		// Normalise magnetometer measurement
		recipNorm = invSqrt(mx * mx + my * my + mz * mz);
		mx *= recipNorm;
		my *= recipNorm;
		mz *= recipNorm;
        
		// Auxiliary variables to avoid repeated arithmetic
		_2q0mx = 2.0f * q0 * mx;
		_2q0my = 2.0f * q0 * my;
		_2q0mz = 2.0f * q0 * mz;
		_2q1mx = 2.0f * q1 * mx;
		_2q0 = 2.0f * q0;
		_2q1 = 2.0f * q1;
		_2q2 = 2.0f * q2;
		_2q3 = 2.0f * q3;
		_2q0q2 = 2.0f * q0 * q2;
		_2q2q3 = 2.0f * q2 * q3;
		q0q0 = q0 * q0;
		q0q1 = q0 * q1;
		q0q2 = q0 * q2;
		q0q3 = q0 * q3;
		q1q1 = q1 * q1;
		q1q2 = q1 * q2;
		q1q3 = q1 * q3;
		q2q2 = q2 * q2;
		q2q3 = q2 * q3;
		q3q3 = q3 * q3;
        
		// Reference direction of Earth's magnetic field
		hx = mx * q0q0 - _2q0my * q3 + _2q0mz * q2 + mx * q1q1 + _2q1 * my * q2 + _2q1 * mz * q3 - mx * q2q2 - mx * q3q3;
		hy = _2q0mx * q3 + my * q0q0 - _2q0mz * q1 + _2q1mx * q2 - my * q1q1 + my * q2q2 + _2q2 * mz * q3 - my * q3q3;
		_2bx = sqrt(hx * hx + hy * hy);
		_2bz = -_2q0mx * q2 + _2q0my * q1 + mz * q0q0 + _2q1mx * q3 - mz * q1q1 + _2q2 * my * q3 - mz * q2q2 + mz * q3q3;
		_4bx = 2.0f * _2bx;
		_4bz = 2.0f * _2bz;
        
		// Gradient descent algorithm corrective step
		s0 = -_2q2 * (2.0f * q1q3 - _2q0q2 - ax) + _2q1 * (2.0f * q0q1 + _2q2q3 - ay) - _2bz * q2 * (_2bx * (0.5f - q2q2 - q3q3) + _2bz * (q1q3 - q0q2) - mx) + (-_2bx * q3 + _2bz * q1) * (_2bx * (q1q2 - q0q3) + _2bz * (q0q1 + q2q3) - my) + _2bx * q2 * (_2bx * (q0q2 + q1q3) + _2bz * (0.5f - q1q1 - q2q2) - mz);
		s1 = _2q3 * (2.0f * q1q3 - _2q0q2 - ax) + _2q0 * (2.0f * q0q1 + _2q2q3 - ay) - 4.0f * q1 * (1 - 2.0f * q1q1 - 2.0f * q2q2 - az) + _2bz * q3 * (_2bx * (0.5f - q2q2 - q3q3) + _2bz * (q1q3 - q0q2) - mx) + (_2bx * q2 + _2bz * q0) * (_2bx * (q1q2 - q0q3) + _2bz * (q0q1 + q2q3) - my) + (_2bx * q3 - _4bz * q1) * (_2bx * (q0q2 + q1q3) + _2bz * (0.5f - q1q1 - q2q2) - mz);
		s2 = -_2q0 * (2.0f * q1q3 - _2q0q2 - ax) + _2q3 * (2.0f * q0q1 + _2q2q3 - ay) - 4.0f * q2 * (1 - 2.0f * q1q1 - 2.0f * q2q2 - az) + (-_4bx * q2 - _2bz * q0) * (_2bx * (0.5f - q2q2 - q3q3) + _2bz * (q1q3 - q0q2) - mx) + (_2bx * q1 + _2bz * q3) * (_2bx * (q1q2 - q0q3) + _2bz * (q0q1 + q2q3) - my) + (_2bx * q0 - _4bz * q2) * (_2bx * (q0q2 + q1q3) + _2bz * (0.5f - q1q1 - q2q2) - mz);
		s3 = _2q1 * (2.0f * q1q3 - _2q0q2 - ax) + _2q2 * (2.0f * q0q1 + _2q2q3 - ay) + (-_4bx * q3 + _2bz * q1) * (_2bx * (0.5f - q2q2 - q3q3) + _2bz * (q1q3 - q0q2) - mx) + (-_2bx * q0 + _2bz * q2) * (_2bx * (q1q2 - q0q3) + _2bz * (q0q1 + q2q3) - my) + _2bx * q1 * (_2bx * (q0q2 + q1q3) + _2bz * (0.5f - q1q1 - q2q2) - mz);
		
        recipNorm = invSqrt(s0 * s0 + s1 * s1 + s2 * s2 + s3 * s3); // normalise step magnitude
		s0 *= recipNorm;
		s1 *= recipNorm;
		s2 *= recipNorm;
		s3 *= recipNorm;
        
		// Apply feedback step
		qDot1 -= beta * s0;
		qDot2 -= beta * s1;
		qDot3 -= beta * s2;
		qDot4 -= beta * s3;
	}
    
	// Integrate rate of change of quaternion to yield quaternion
	q0 += qDot1 * Te;
	q1 += qDot2 * Te;
	q2 += qDot3 * Te;
	q3 += qDot4 * Te;
    
	// Normalise quaternion
	recipNorm = invSqrt(q0 * q0 + q1 * q1 + q2 * q2 + q3 * q3);
	q0 *= recipNorm;
	q1 *= recipNorm;
	q2 *= recipNorm;
	q3 *= recipNorm;
    
    // Backup for next iteration
    x->q0 = q0;
    x->q1 = q1;
    x->q2 = q2;
    x->q3 = q3;
   
    // From quaternions, compute Euler angles
	if (q0 == 1.0){
		angle = 0.0;
		ixe = 33.0;
		y = 33.0;
		z = 33.0;
        
	} else if (q0 == 0.0){
        
		angle = 180.0;
		ixe = q1;
		y = q2;
		z = q3;
		
	} else {
        q0squared = q0 * q0;
        is = invSqrt(1.0 - q0squared);
        angle = 2.0 * acos(q0) * 180.0 / PI;
        ixe = q1 * is;
        y = q2 * is;
        z = q3 * is;
	}
    // Axis-angle output

    atom_setfloat(myList, angle);
    atom_setfloat(myList + 1, ixe);
    atom_setfloat(myList + 2,   y);
    atom_setfloat(myList + 3,   z);
	outlet_list( x->AxisAngle , 0L, 4, myList);
    
    // Euler angles output
    angle =  angle * pisur180;
    
    si = sin(angle); si2 = sin(0.5 * angle);
	co = cos(angle); co2 = cos(0.5 * angle);
	t = 1 - co;
    test = ixe * y * t + z * si;
    if (test > 0.998) {
        heading = 2 * atan2(ixe * si2,co2) ;
        attitude = 0.5 * PI ;
        bank = 0. ;
     }
    else if (test < -0.998) {
        heading = -2 * atan2(ixe * si2,co2);
        attitude = -0.5 * PI ;
        bank = 0. ;
    }
	else {
        heading = atan2(y * si - ixe * z * t, 1.- (y*y+ z*z ) * t);
        attitude = asin(ixe * y * t + z * si);
        bank = atan2(ixe * si - y * z * t , 1 - (ixe * ixe + z * z) * t);
    }
    
    atom_setfloat(myList, heading);
	atom_setfloat(myList + 1, attitude);
    atom_setfloat(myList + 2, bank);
	outlet_list( x->EulerAngles , 0L, 3, myList);

}

//***********************************************************************************************************************************************//

void *AHRS_new(double beta, double Te)
{
	t_AHRS *x;                      // local variable (pointer to a t_AHRS data structure)
	x = object_alloc(AHRS_class);   // create a new instance of this object
	x->beta = (float)beta;
	x->Te = (float)Te;
    x->EulerAngles = listout(x);         // create a list outlet and assign it to our outlet variable in the instance's data structure
    x->AxisAngle = listout(x);         // create a list outlet and assign it to our outlet variable in the instance's data structure
    AHRS_init(x);
    post("start with beta = %f, Te = %f", x->beta, x->Te);
	return x;                       // return a reference to the object instance
}
//***********************************************************************************************************************************************//

void AHRS_assist(t_AHRS *AHRS, void *b, long msg, long arg, char *s)
{
	if (msg == ASSIST_OUTLET) {
		switch (arg) {
			case 0: sprintf(s, "%s", "Axis-Angle list");
				break;
			case 1: sprintf(s, "%s", "Euler Angles list");
				break;
		}
	}
	else if(msg == ASSIST_INLET)
		sprintf(s, "%s", "(Sensors data)");
}

void AHRS_init(t_AHRS *x)
{   // initialisation of sensor frame relative to auxiliary frame quaternion
    x->q0 = 1.0f;
    x->q1 = 0.0f;
    x->q2 = 0.0f;
    x->q3 = 0.0f;
}

//***********************************************************************************************************************************************//

void AHRS_free(t_AHRS *x)
{
		post("Fine!....BYE!", 0);
}

//***********************************************************************************************************************************************//
// Fast inverse square-root
// See: http://en.wikipedia.org/wiki/Fast_inverse_square_root

float invSqrt(float x) {
    
    // float y = 1.0f/sqrt(x); slower but make the job
    
    float xx = (Float32)x;
	float halfx = 0.5f * xx;
	float y = xx;
	long i = *(long*)&y;
	i = 0x5f3759df - (i>>1);
	y = *(float*)&i;
	y = y * (1.5f - (halfx * y * y));
	return y;
}

//***********************************************************************************************************************************************//

void AHRS_dump(t_AHRS *x)
{
	post("beta, %f",x->beta);
    post("Te, %f",  x->Te);
    post("q0, %f",  x->q0);
    post("q1, %f",  x->q1);
    post("q2, %f",  x->q2);
    post("q3, %f",  x->q3);
}

