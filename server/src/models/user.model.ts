export interface User {
    username: string;
    email: string;
    acceptedTerms: boolean;
    password: string;
    confirmedPassword: string;
}

export interface GoogleAppleAuthUserObject {
  token: string;
  user: {
    id: string;
    email: string;
    name: string;
    picture?: string;
  };
}

export interface RegisterLoginAuthUserObject {
  token: string;
  user: UserData;
}

export interface AwaitingAuthAuthUserObject {
  token: string;
  user: UserData;
}

export interface UserData {
  id: string;
  name: string;
  email: string;
  success: boolean;
  message: string;
  createdAt: FirebaseFirestore.Timestamp | Date | string;
  updatedAt: FirebaseFirestore.Timestamp | Date | string;
  lastLogin: FirebaseFirestore.Timestamp | Date | string;
  photoUrl?: string | null;
  provider?: string | null;
}

export interface RegisterLoginAuthUserObject {
  token: string;
  user: UserData;
}

export interface FirestoreUserData {
  names?: string;
  name?: string;
  email: string;
  password?: string;
  photoUrl?: string | null;
  provider?: string | null;
  createdAt: FirebaseFirestore.Timestamp | Date | string;
  updatedAt: FirebaseFirestore.Timestamp | Date | string;
  lastLogin?: FirebaseFirestore.Timestamp | Date | string;
  lastAccessed?: FirebaseFirestore.Timestamp | Date | string;
  acceptedTerms?: boolean;
}